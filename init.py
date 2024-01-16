import subprocess as sp
from datetime import datetime
import os
import platform

import pathlib 
from decouple import Config, RepositoryEnv
import json


def run_shell_cmd(cmd: str) -> str:
    """
    Execute a shell command and return the combined standard output and standard error.

    Parameters:
    - cmd (str): The shell command to be executed.

    Returns:
    - str: The combined standard output and standard error of the executed command.

    Raises:
    - CalledProcessError: If the command exits with a non-zero status.

    Example:
    >>> run_shell_cmd("ls -l")
    'total 4\n-rw-r--r-- 1 user user 15 Jan 15 12:00 example.txt'
    """
    result = sp.run(cmd, stdout=sp.PIPE, stderr=sp.PIPE, text=True, shell=True)
    output = (result.stdout + result.stderr).strip()
    print(output)
    return output

def run_ps_cmd(cmd: list[str], log: bool=True) -> str:
    if platform.system() == "Windows":
        full_cmd = ['powershell', '-Command'] + cmd
    else:
        full_cmd = cmd
    full_cmd_str = " ".join(cmd)
    if log: print(f"Running command: {full_cmd_str}\n")
    result = sp.run(full_cmd, stdout=sp.PIPE, stderr=sp.PIPE, text=True, shell=True)
    combined_output = result.stdout + result.stderr
    output = combined_output.strip()
    if log: print(f"Output: {output}\n")
    return output


    auth(email)
    if project_exist(proj_name=""):
        return
    
    proj_id = make_proj_id(proj_name) # Create project
    run_ps_cmd(['gcloud', 'projects', 'create', proj_id, f"--name={proj_name}"])
    
    # Link billing account
    try:
        link_billing_account(proj_id)
    except:
        print("Could not link billing account to project. Please do it manually.")
        return
    
    # Enable services API
    for service in services:
        run_ps_cmd(['gcloud', 'services', 'enable', f'{service}.googleapis.com', f'--project={proj_id}'])
    
    get_sa_cred_file(proj_id, proj_name)

def write_file(file_path: str, data: str=None):
    directory = os.path.dirname(file_path)
    if not os.path.exists(directory):
        os.makedirs(directory)
    
    if not os.path.exists(file_path):
        with open(file_path, 'w') as f:
            if data:
                f.write(data)     

class InitGCP:
    def __init__(self, proj_name: str, services: list[str], key_dir: str=None, email: str=None) -> None:
        self.proj_name = proj_name
        self.proj_id = self.make_proj_id()
        self.services = services
        self.key_dir = key_dir if key_dir else self.default_key_dir()
        self.email = email
        self.auth()
        

    def auth(self):
        if self.email == None:
            # get variable from .env file in the project's root directory
            BASE_DIR = pathlib.Path(__file__).parent
            ENV_PATH = BASE_DIR / '.env'
            env_config = Config(RepositoryEnv(ENV_PATH))
            email = env_config.get('email')
        
        mail_list = run_ps_cmd(['gcloud', 'auth', 'list', '--format=json'], log=False)
        mail_list_json = json.loads(mail_list.replace("\n", ""))
        for account in mail_list_json:
            if account["account"] == email:
                if account["status"] == "ACTIVE":
                    print("Authenticated as "+email)
                    return
                else:
                    run_ps_cmd(['gcloud', 'auth', 'login', email], log=False)
                    print("Authenticated as "+email)
                    return
        run_ps_cmd(['gcloud', 'auth', 'login']) 
    
    def project_exist(self):
        projects_list = run_ps_cmd(['gcloud', 'projects', 'list', '--format=json'], log=False)
        projects_list_json = json.loads(projects_list.replace("\n", ""))
        for proj in projects_list_json:
            if proj["name"] == self.proj_name:
                return True
        return False
    
    def make_proj_id(self):
        time_iso_now = datetime.utcnow().isoformat() # current ISO time
        time_iso_now = time_iso_now.replace(".", "").replace("T", "").replace(":", "").replace("-", "") # remove special characters from ISO time
        proj_id = f"{self.proj_name}-{time_iso_now}"[:30]
        return proj_id
   
    def default_key_dir(self) -> str:
        key_dir = os.path.join(os.getcwd(), "gcp_project")
        if not os.path.exists(key_dir):
            os.makedirs(key_dir)
        return key_dir
   
    def get_sa_cred_file(self) -> None:
        # Create service account, grant owner role and create credentials file
        key_path = os.path.join(self.key_dir, "credentials.json") # path to save the credentials file
        sa_email = f'{self.proj_name}@{self.proj_id}.iam.gserviceaccount.com'
        run_ps_cmd(['gcloud', 'iam', 'service-accounts', 'create', self.proj_name, f"--project={self.proj_id}"])
        run_ps_cmd(['gcloud', 'projects', 'add-iam-policy-binding', self.proj_id, f'--member=serviceAccount:{sa_email}', '--role=roles/owner'])
        run_ps_cmd(['gcloud', 'iam', 'service-accounts', 'keys', 'create', f'"{key_path}"', f'--iam-account={sa_email}', f"--project={self.proj_id}"])
        
    def link_billing_account(self):
        # Get billing accounts lists
        output = run_ps_cmd(['gcloud', 'alpha', 'billing', 'accounts', 'list', '--format=json'], log=False)
        output_json = json.loads(output.replace("\n", ""))
        bill_acc_id = output_json[0]["name"].split("/")[-1]
        # Link billing account to project
        run_ps_cmd(['gcloud', 'alpha', 'billing', 'projects', 'link', f'{self.proj_id}', f'--billing-account={bill_acc_id}'])
        
    def init(self):
        if self.project_exist():
            print("Project already exists.")
            return
        
        run_ps_cmd(['gcloud', 'projects', 'create', self.proj_id, f"--name={self.proj_name}"]) # Create project
        
        # Link billing account
        try:
            self.link_billing_account()
        except:
            print("Could not link billing account to project. Please do it manually.")
            return
            
        # Enable services API
        for service in self.services:
            run_ps_cmd(['gcloud', 'services', 'enable', f'{service}.googleapis.com', f'--project={self.proj_id}'])
            
        self.get_sa_cred_file()
        
        return self.proj_id
    
def get_id_from_proj_name(proj_name: str):
    projects_list = run_ps_cmd(['gcloud', 'projects', 'list', '--format=json'], log=False)
    projects_list_json = json.loads(projects_list.replace("\n", ""))
    for proj in projects_list_json:
        if proj["name"] == proj_name:
            return proj["projectId"]
    return None


if __name__ == "__main__":
    proj_name = "web-scraping"
    services = ['serviceusage', 'cloudresourcemanager', 'iam', 'compute']
    
    proj_id_file_path = os.path.join(os.getcwd(), "gcp_project", "project_id.txt")
    sa_email_file_path = os.path.join(os.getcwd(), "gcp_project", "sa_email.txt")
    
    
    gcp_init = InitGCP(proj_name="web-scraping", services=services)
    # proj_id = gcp_init.init()
    proj_id = get_id_from_proj_name(proj_name)
    sa_email = f"{proj_name}@{proj_id}.iam.gserviceaccount.com"
    
    write_file(proj_id_file_path, proj_id)
    write_file(sa_email_file_path, sa_email)
    
    