import paramiko
import os
import sys
from dotenv import load_dotenv

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

load_dotenv(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))

HOST = os.getenv("REMOTE_HOST", "207.148.13.164")
USER = os.getenv("REMOTE_USER", "root")
PORT = int(os.getenv("REMOTE_PORT", "22"))
PASSWORD = os.getenv("REMOTE_PASSWORD")

def main():
    if not PASSWORD:
        sys.exit("Set REMOTE_PASSWORD in your environment or bizideas_backend/.env before checking activity.")

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(HOST, port=PORT, username=USER, password=PASSWORD, timeout=10)
        print("Connected to remote server to check activity...")
        
        # Check active apt or pip processes
        print("\n=== Active package manager/install processes ===")
        stdin, stdout, stderr = ssh.exec_command("ps aux | grep -E 'apt|dpkg|pip|uvicorn|python'")
        print(stdout.read().decode('utf-8'))
        
        # Check last lines of the log file on the remote server
        print("\n=== Last lines of remote api.log ===")
        stdin, stdout, stderr = ssh.exec_command("tail -n 20 /root/bizideas_backend/api.log")
        print(stdout.read().decode('utf-8'))
        
    except Exception as e:
        print(f"Failed to check activity: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    main()
