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
        sys.exit("Set REMOTE_PASSWORD in your environment or bizideas_backend/.env before running the interactive check.")

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(HOST, port=PORT, username=USER, password=PASSWORD, timeout=10)
        print("Running uvicorn in interactive session to catch errors...")
        
        # Execute command synchronously with a 5 second timeout to catch initial errors
        stdin, stdout, stderr = ssh.exec_command(
            "cd /root/bizideas_backend && ./venv/bin/uvicorn main:app --host 0.0.0.0 --port 80",
            timeout=5
        )
        
        # Read stdout/stderr
        print("[STDOUT]")
        print(stdout.read().decode('utf-8'))
        print("[STDERR]")
        print(stderr.read().decode('utf-8'))
        
    except Exception as e:
        print(f"Session finished or timed out: {e}")
        # Try checking the log file contents if it timed out (meaning it might have started)
        try:
            stdin, stdout, stderr = ssh.exec_command("cat /root/bizideas_backend/api.log")
            print("=== Remote log file content ===")
            print(stdout.read().decode('utf-8'))
        except Exception:
            pass
    finally:
        ssh.close()

if __name__ == "__main__":
    main()
