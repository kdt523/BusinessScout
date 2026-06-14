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
        sys.exit("Set REMOTE_PASSWORD in your environment or bizideas_backend/.env before running diagnostics.")

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    try:
        ssh.connect(HOST, port=PORT, username=USER, password=PASSWORD, timeout=10)
        print("Connected to remote server for diagnostics...")
        
        # 1. Check uvicorn process
        print("\n=== Checking uvicorn processes ===")
        stdin, stdout, stderr = ssh.exec_command("ps aux | grep uvicorn")
        print(stdout.read().decode('utf-8'))
        
        # 2. Check netstat/ss output for port 80 or 8000
        print("\n=== Checking listening ports (netstat) ===")
        stdin, stdout, stderr = ssh.exec_command("ss -tlnp")
        print(stdout.read().decode('utf-8'))
        
        # 3. Read uvicorn logs
        print("\n=== Reading /root/bizideas_backend/api.log ===")
        stdin, stdout, stderr = ssh.exec_command("tail -n 30 /root/bizideas_backend/api.log")
        print(stdout.read().decode('utf-8'))
        
        # 4. Check firewall status (ufw)
        print("\n=== Checking firewall status (ufw) ===")
        stdin, stdout, stderr = ssh.exec_command("ufw status || iptables -L -n")
        print(stdout.read().decode('utf-8'))
        
    except Exception as e:
        print(f"Diagnostics failed: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    main()
