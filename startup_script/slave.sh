#!/bin/bash

startup_log_file="/tmp/startup_log.txt" # Log file
exec &> $startup_log_file # Redirect stdout and stderr to a log file
sudo apt-get update # Update package index

# Get variables from metadata
attributes=(BASE_DIR PROJECT USER)
for attr in "${attributes[@]}"; do
  value=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$attr" -H "Metadata-Flavor: Google")
  declare "$attr=$value"
done


# CHECKING
PROJ_PATH="$BASE_DIR/$PROJECT"
echo $PROJ_PATH
if [ ! -d "$PROJ_PATH" ]; then
    echo "Applications have not been initialized."

    ##########################################
    ##### SET UP PORJECT AND ENVIRONMENT #####
    ##########################################

    # Install packages
    sudo apt-get install git python3-pip python3-venv jq postgresql-client -y

    # Clone the GitHub project
    sudo git clone https://github.com/$USER/$PROJECT.git $PROJ_PATH

    # Set up the virtual environment
    VENV="$BASE_DIR/($PROJECT)"_"env"
    VENV_PATH="$VENV/bin/activate"
    python3 -m venv "$VENV"
    source "$VENV_PATH"
    pip3 install -r "$PROJ_PATH/requirements.txt"
    deactivate

    sleep 300

else
    echo "Applications have already been initialized."
fi

project_log_folder="/var/log/$PROJECT"
mkdir -p "$project_log_folder"

source "$VENV_PATH"
cd "$PROJ_PATH"
nohup celery -A make_celery worker --loglevel=info --logfile=$project_log_folder/celery_worker.log --pidfile=$project_log_folder/celery_worker.pid & 
gunicorn -w 1 -b 0.0.0.0:5000 $PROJ_PATH/wsgi:app --daemon --pid gunicorn.pid --access-logfile $project_log_folder/gunicorn_access.log --error-logfile $project_log_folder/gunicorn_error.log

nohup python3 $PROJ_PATH/trigger_initial_runs.py > $project_log_folder/trigger_initial_runs.log 2>&1 &

echo "Startup script completed successfully."


