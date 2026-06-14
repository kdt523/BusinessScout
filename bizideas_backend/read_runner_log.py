import paramiko
import os
import sys
from dotenv import load_dotenv

# Load env from bizideas_backend
dotenv_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
load_dotenv(dotenv_path)

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
        print("Connected to remote server to read runner.log...")
        
        # Check if band_runner.py is running
        print("\n=== Checking if band_runner.py is running ===")
        stdin, stdout, stderr = ssh.exec_command("ps aux | grep band_runner")
        print(stdout.read().decode('utf-8'))
        
        print("\n=== Last lines of remote runner.log ===")
        stdin, stdout, stderr = ssh.exec_command("tail -n 50 /root/bizideas_backend/runner.log")
        print(stdout.read().decode('utf-8'))
        
        print("\n=== Error output of remote runner.log (if any) ===")
        stdin, stdout, stderr = ssh.exec_command("cat /root/bizideas_backend/runner.log | grep -E -i 'error|fail|exception'")
        print(stdout.read().decode('utf-8'))
        
    except Exception as e:
        print(f"Failed to check activity: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    main()
