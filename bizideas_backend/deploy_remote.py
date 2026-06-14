import os
import posixpath
import sys
import time
from dotenv import load_dotenv

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Ensure paramiko and scp are installed locally
try:
    import paramiko
    from paramiko import SFTPClient
except ImportError:
    print("Installing paramiko dependency locally...")
    os.system(f"{sys.executable} -m pip install paramiko")
    import paramiko

load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))

# Server Configuration
HOST = os.getenv("REMOTE_HOST", "your_vps_ip")
USER = os.getenv("REMOTE_USER", "ubuntu")
PORT = int(os.getenv("REMOTE_PORT", "22"))
PASSWORD = os.getenv("REMOTE_PASSWORD")

LOCAL_BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
REMOTE_DEPLOY_DIR = "/root/bizideas_backend"

REMOTE_ENV_KEYS = [
    "PORT",
    "HOST",
    "USE_SIMULATOR",
    "MAPBOX_ACCESS_TOKEN",
    "GEMINI_API_KEY",
    "ANTHROPIC_API_KEY",
    "OPENAI_API_KEY",
    "FEATHERLESS_API_KEY",
    "FEATHERLESS_MODEL",
    "AIMLAPI_API_KEY",
    "AIMLAPI_MODEL",
    "GOOGLE_MAPS_API_KEY",
    "BAND_REST_URL",
    "BAND_WS_URL",
    # Legacy single-agent Band keys (kept for backwards compatibility)
    "THENVOI_AGENT_ID",
    "THENVOI_API_KEY",
    "THENVOI_API_URL",
    "THENVOI_REST_URL",
    "THENVOI_WS_URL",
    # Real Band multi-agent credentials (4 separate remote agents)
    "BAND_ORCHESTRATOR_ID",
    "BAND_ORCHESTRATOR_KEY",
    "BAND_ORCHESTRATOR_HANDLE",
    "BAND_LOCATION_SCOUT_ID",
    "BAND_LOCATION_SCOUT_KEY",
    "BAND_LOCATION_SCOUT_HANDLE",
    "BAND_COMPETITOR_ANALYST_ID",
    "BAND_COMPETITOR_ANALYST_KEY",
    "BAND_COMPETITOR_ANALYST_HANDLE",
    "BAND_BUSINESS_PLANNER_ID",
    "BAND_BUSINESS_PLANNER_KEY",
    "BAND_BUSINESS_PLANNER_HANDLE",
    "BRIGHTDATA_CUSTOMER_ID",
    "BRIGHTDATA_ZONE_NAME",
    "BRIGHTDATA_ZONE_PASSWORD",
    "BRIGHTDATA_PROXY_HOST",
    "BRIGHTDATA_PROXY_PORT",
    "BRIGHTDATA_API_KEY",
]


def build_remote_env() -> str:
    defaults = {
        "PORT": "80",
        "HOST": "0.0.0.0",
        "USE_SIMULATOR": "true",
        "BAND_REST_URL": "https://app.band.ai",
        "BAND_WS_URL": "wss://app.band.ai/api/v1/socket/websocket",
    }
    lines = []
    for key in REMOTE_ENV_KEYS:
        if key == "PORT":
            value = "80"
        else:
            value = os.getenv(key)
        if value is None:
            value = defaults.get(key, "")
        lines.append(f"{key}={value}")
    return "\n".join(lines) + "\n"

def upload_directory(sftp, local_dir, remote_dir):
    """
    Recursively uploads a local directory to a remote directory via SFTP.
    Excludes venv, pycache, static files reports, env files, and logs.
    """
    print(f"Uploading {local_dir} to {remote_dir}...")
    try:
        sftp.mkdir(remote_dir)
    except IOError:
        pass # Directory already exists

    for entry in os.listdir(local_dir):
        # Exclusions
        if entry in [
            "venv", ".venv", "__pycache__", "static", ".git", ".env", 
            "deploy_remote.py", "verify_pipeline.py", ".DS_Store"
        ]:
            continue

        local_path = os.path.join(local_dir, entry)
        remote_path = posixpath.join(remote_dir, entry)

        if os.path.isdir(local_path):
            upload_directory(sftp, local_path, remote_path)
        else:
            print(f" -> Uploading file: {entry}")
            sftp.put(local_path, remote_path)

def execute_remote_commands(ssh, commands):
    """
    Executes a list of commands on the remote server.
    """
    for cmd in commands:
        print(f"\n⚡ Executing remote command: {cmd}")
        stdin, stdout, stderr = ssh.exec_command(cmd)
        
        # If it's a background command, do not wait for completion
        if "nohup" in cmd and "&" in cmd:
            print("Background process launched. Skipping exit status wait.")
            time.sleep(2.0)
            continue
            
        # Wait for command completion
        exit_status = stdout.channel.recv_exit_status()
        
        # Print stdout/stderr
        out_content = stdout.read().decode('utf-8').strip()
        err_content = stderr.read().decode('utf-8').strip()
        
        if out_content:
            print(f"[STDOUT]\n{out_content}")
        if err_content:
            print(f"[STDERR]\n{err_content}")
            
        print(f"Exit Code: {exit_status}")
        if exit_status != 0 and "kill" not in cmd:
            raise RuntimeError(f"Remote command failed with exit code {exit_status}: {cmd}")

def main():
    print("🚀 Starting Remote Deployment to BizIdeas Server...")
    if not PASSWORD:
        sys.exit("Set REMOTE_PASSWORD in your environment or bizideas_backend/.env before deploying.")
    
    # Initialize SSH Client
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        print(f"Connecting to {HOST} on port {PORT} as {USER}...")
        key_path = os.getenv("REMOTE_KEY", os.path.expanduser("~/.ssh/your_key.pem"))
        connect_kwargs = {
            "hostname": HOST,
            "port": PORT,
            "username": USER,
            "timeout": 15
        }
        if os.path.exists(key_path):
            print(f"Using SSH key: {key_path}")
            connect_kwargs["key_filename"] = key_path
        else:
            print("SSH key not found, using password.")
            connect_kwargs["password"] = PASSWORD
            
        ssh.connect(**connect_kwargs)
        print("✅ Connection Established successfully!")
        
        # Initialize SFTP Client
        sftp = ssh.open_sftp()
        
        # 1. Clean and create remote deployment directory
        print("\n🧹 Cleaning remote directory...")
        ssh.exec_command(
            f"find {posixpath.dirname(REMOTE_DEPLOY_DIR)} -maxdepth 1 "
            f"-name '{posixpath.basename(REMOTE_DEPLOY_DIR)}*' -exec rm -rf {{}} +"
        )
        time.sleep(1.0)
        
        # 2. Upload source code
        upload_directory(sftp, LOCAL_BACKEND_DIR, REMOTE_DEPLOY_DIR)
        
        # Re-create reports directory in remote static
        try:
            sftp.mkdir(f"{REMOTE_DEPLOY_DIR}/static")
            sftp.mkdir(f"{REMOTE_DEPLOY_DIR}/static/reports")
        except IOError:
            pass

        # 3. Create .env on remote server
        print("\n📝 Creating remote configuration...")
        with sftp.file(f"{REMOTE_DEPLOY_DIR}/.env", "w") as remote_env:
            remote_env.write(build_remote_env())

        # Close SFTP
        sftp.close()
        
        use_sim = os.getenv("USE_SIMULATOR", "true").strip().lower() in ("1", "true", "yes")
        
        # 4. Prepare remote environment and run server
        remote_setup_commands = [
            # Open firewall port 80
            "ufw allow 80/tcp || true",
            
            # Stop nginx and apache2 if running to free up port 80
            "systemctl stop nginx || true",
            "systemctl stop apache2 || true",
            
            # Kill any existing uvicorn and runner processes
            "fuser -k 80/tcp || true",
            "pkill -f uvicorn || true",
            "pkill -f band_runner.py || true",
            
            # Create virtual env
            f"python3 -m venv {REMOTE_DEPLOY_DIR}/venv",
            
            # Upgrade pip and install requirements
            f"{REMOTE_DEPLOY_DIR}/venv/bin/pip install --upgrade pip",
            f"{REMOTE_DEPLOY_DIR}/venv/bin/pip install -r {REMOTE_DEPLOY_DIR}/requirements.txt",
            
            # Start backend in background using nohup, routing logs to api.log
            f"cd {REMOTE_DEPLOY_DIR} && nohup {REMOTE_DEPLOY_DIR}/venv/bin/uvicorn main:app --host 0.0.0.0 --port 80 > {REMOTE_DEPLOY_DIR}/api.log 2>&1 < /dev/null &",
        ]
        
        if not use_sim:
            print("ℹ️ Live Band Platform mode selected (USE_SIMULATOR=false).")
            print("⚡ Starting real Band agents runner (band_runner.py) in the background...")
            remote_setup_commands.append(
                f"cd {REMOTE_DEPLOY_DIR} && nohup {REMOTE_DEPLOY_DIR}/venv/bin/python band_runner.py > {REMOTE_DEPLOY_DIR}/runner.log 2>&1 < /dev/null &"
            )
        else:
            print("ℹ️ Simulator mode selected (USE_SIMULATOR=true). Band agents runner will not be started.")
        
        execute_remote_commands(ssh, remote_setup_commands)
        
        # 5. Wait a moment and check status
        print("\n⏳ Verifying server start...")
        time.sleep(3.0)
        stdin, stdout, stderr = ssh.exec_command("ps aux | grep uvicorn")
        print(f"[PROCESS STATUS]\n{stdout.read().decode('utf-8')}")
        
        # Test HTTP response locally on the server
        stdin, stdout, stderr = ssh.exec_command("curl -s http://localhost/")
        print(f"[HTTP LOCAL RESPONSE]\n{stdout.read().decode('utf-8')}")
        
        print("\n🎉 Deployment completed successfully!")
        print(f"Backend is live at: http://{HOST}/")
        
    except Exception as e:
        print(f"\n❌ Deployment failed: {e}")
        sys.exit(1)
    finally:
        ssh.close()

if __name__ == "__main__":
    main()
