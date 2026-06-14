import paramiko
import os
import sys
from dotenv import load_dotenv

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

# Load env from bizideas_backend
dotenv_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
load_dotenv(dotenv_path)

HOST = os.getenv("REMOTE_HOST", "207.148.13.164")
USER = os.getenv("REMOTE_USER", "root")
PORT = int(os.getenv("REMOTE_PORT", "22"))
PASSWORD = os.getenv("REMOTE_PASSWORD")

def main():
    if not PASSWORD:
        sys.exit("Set REMOTE_PASSWORD in your environment before checking logs.")

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(HOST, port=PORT, username=USER, password=PASSWORD, timeout=10)
        print("Connected to remote server to read api.log...")
        
        print("\n=== Last 250 lines of remote api.log ===")
        stdin, stdout, stderr = ssh.exec_command("tail -n 250 /root/bizideas_backend/api.log")
        print(stdout.read().decode('utf-8'))
        
    except Exception as e:
        print(f"Failed to check activity: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    main()
