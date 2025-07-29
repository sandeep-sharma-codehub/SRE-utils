import paramiko
import os
from concurrent.futures import ThreadPoolExecutor

# Configuration
PRIVATE_KEY_PATH = os.path.expanduser("~/.ssh/id_rsa") # Your private key
PUBLIC_KEY_PATH = os.path.expanduser("~/.ssh/id_rsa.pub") # Your public key
REMOTE_SSH_DIR = ".ssh"
AUTHORIZED_KEYS_FILE = os.path.join(REMOTE_SSH_DIR, "authorized_keys")
MAX_WORKERS = 50 # Adjust based on your system resources and network
INITIAL_PASSWORD = "your_initial_password" # Use ONLY for initial key deployment, consider secure input or a temporary credential management system.

def deploy_ssh_key(server_info):
    host, user = server_info.split('@')
    print(f"Attempting to deploy key to {user}@{host}...")
    try:
        # Initialize SSH client
        client = paramiko.SSHClient()
        client.load_system_host_keys() # Load known hosts from ~/.ssh/known_hosts
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy()) # Use ONLY for initial setup, otherwise be strict.

        # Attempt connection with password for initial key deployment

        client.connect(hostname=host, username=user, password=INITIAL_PASSWORD, timeout=10)

        # Read the public key
        with open(PUBLIC_KEY_PATH, 'r') as f:
            public_key_content = f.read().strip()

        sftp_client = client.open_sftp()

        # Ensure .ssh directory exists and has correct permissions
        try:
            sftp_client.stat(REMOTE_SSH_DIR)
        except IOError:
            sftp_client.mkdir(REMOTE_SSH_DIR)
            print(f"Created {REMOTE_SSH_DIR} on {host}")
        sftp_client.chmod(REMOTE_SSH_DIR, 0o700)

        # Check if key already exists, append if not
        try:
            with sftp_client.open(AUTHORIZED_KEYS_FILE, 'r') as f:
                current_authorized_keys = f.read()
        except IOError:
            current_authorized_keys = ""

        if public_key_content not in current_authorized_keys:
            with sftp_client.open(AUTHORIZED_KEYS_FILE, 'a') as f:
                f.write(public_key_content + "\n")
            print(f"Appended public key to {AUTHORIZED_KEYS_FILE} on {host}")
        else:
            print(f"Public key already present on {host}")

        # Set correct permissions for authorized_keys
        sftp_client.chmod(AUTHORIZED_KEYS_FILE, 0o600)

        sftp_client.close()
        client.close()
        print(f"Successfully deployed key to {user}@{host}")
        return f"{user}@{host}: Success"

    except paramiko.AuthenticationException:
        print(f"Authentication failed for {user}@{host}. Check password or existing key.")
        return f"{user}@{host}: Authentication Failed"
    except paramiko.SSHException as e:
        print(f"SSH error for {user}@{host}: {e}")
        return f"{user}@{host}: SSH Error - {e}"
    except Exception as e:
        print(f"An unexpected error occurred with {user}@{host}: {e}")
        return f"{user}@{host}: Unexpected Error - {e}"

if __name__ == "__main__":
    if not os.path.exists(PUBLIC_KEY_PATH):
        print(f"Error: Public key not found at {PUBLIC_KEY_PATH}. Please generate it first.")
        exit(1)


    server_list = []
    try:
        with open("servers.txt", "r") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'): # Ignore empty lines and comments
                    server_list.append(line)
    except FileNotFoundError:
        print("Error: servers.txt not found. Please create a file with one server (user@host) per line.")
        exit(1)

    if not server_list:
        print("No servers found in servers.txt.")
        exit(0)

    results = []
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        # Map the deploy_ssh_key function to each server
        futures = [executor.submit(deploy_ssh_key, server) for server in server_list]
        for future in futures:
            results.append(future.result())

    print("\n--- Deployment Summary ---")
    for result in results:
        print(result)

