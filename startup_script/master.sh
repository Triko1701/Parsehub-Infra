#!/bin/bash

startup_log_file="/tmp/startup_log.txt" # Log file
exec &> $startup_log_file # Redirect stdout and stderr to a log file
sudo apt-get update # Update package index

# Get variables from metadata
attributes=(BASE_DIR PROJECT USER POSTGRES_PASSWORD REDIS_PASSWORD)
for attr in "${attributes[@]}"; do
  value=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$attr" -H "Metadata-Flavor: Google")
  declare "$attr=$value"
done

# CHECKING
PROJ_PATH="$BASE_DIR/$PROJECT"
echo $PROJ_PATH
if [ ! -d "$PROJ_PATH" ]; then
    echo "Applications have not been initialized."

    ##########################
    ##### INSTALL DOCKER #####
    ##########################

    # Add Docker's official GPG key:
    sudo apt-get install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    echo "Docker installed successfully."

    ##############################################
    ##### INSTALL AND RUN POSTGRESQL DOCKER  #####
    ##############################################

    COMPOSE_DIR="$BASE_DIR/postgresql_docker"
    COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

    mkdir -p "$COMPOSE_DIR"

    cat <<EOT >> "$COMPOSE_FILE"
version: '3.9'

services:
    postgres:
        image: postgres:latest
        container_name: postgres
        ports:
            - "5432:5432"
        environment:
            POSTGRES_USER: "$USER"
            POSTGRES_PASSWORD: "$POSTGRES_PASSWORD"
            POSTGRES_DB: "$PROJECT"
        volumes:
            - ./postgres_logs:/var/log/postgres
        restart: always

    redis:
        image: redis:latest
        container_name: redis
        ports:
            - "6379:6379"
        command: redis-server --requirepass "$REDIS_PASSWORD"
        volumes:
            - ./redis_logs:/var/log/redis
        restart: always
EOT

    sudo docker compose -f $COMPOSE_FILE up -d
    echo "Docker containers started successfully."

    #############################################
    ##### CLONE PROJECT & SETUP ENVIRONMENT #####
    #############################################

    # Install packages
    sudo apt-get install git python3-pip python3-venv jq postgresql-client net-tools -y

    # Clone the project
    sudo git clone https://github.com/$USER/$PROJECT.git $PROJ_PATH

    # Set up the virtual environment
    VENV="${PROJ_PATH}_env"
    VENV_PATH="$VENV/bin/activate"
    python3 -m venv "$VENV"
    source "$VENV_PATH"
    pip3 install -r "$PROJ_PATH/requirements.txt"

    echo "Clone project and setup environment sucessfully."

    ##########################################
    ##### INIT DB & CREATE THE CRON JOBS #####
    ##########################################

    project_log_folder="/var/log/$PROJECT"
    mkdir -p "$project_log_folder"

    # Initialize DB
    nohup python3 "$PROJ_PATH/init_db.py" > $project_log_folder/init_db.log 2>&1 &

    # Cron jobs commands
    ASSIGN_RUNS=". \"$VENV_PATH\" && python3 \"$PROJ_PATH/assign_runs.py\" >> \"$project_log_folder/assign_runs.log\" 2>&1"
    CONTROL_SLAVE=". \"$VENV_PATH\" && python3 \"$PROJ_PATH/control_slave.py\" >> \"$project_log_folder/control_slave.log\" 2>&1"

    # Add cron jobs
    (crontab -l ; echo "0 0 * * * TZ=Australia/Sydney $ASSIGN_RUNS") | crontab -
    (crontab -l ; echo "*/15 * * * * TZ=Australia/Sydney $CONTROL_SLAVE") | crontab -

    echo "Setup cron jobs successfully."

    rdp_install_path="$PROJ_PATH/install_rdp_xfce4.sh"
    chmod +x "$rdp_install_path"
    # bash "$rdp_install_path"
    # echo "Install RDP xfce4 successfully."
    
else
    echo "Applications have already been initialized."
fi
echo "Startup script completed successfully."