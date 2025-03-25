#!/bin/bash
# -------------------------------------------------------------------
#   ./sync_docker_home_s3.sh TENANT_CD
#
# -------------------------------------------------------------------

set -u
set -o pipefail

# convert to lowercase.
TENANT_CD=$(echo "$1" | tr '[:upper:]' '[:lower:]')

LOG_FILE="/var/log/jupyter/sync_docker_home_s3_$(date +%Y%m%d%H).log"

ADMIN_EMAIL="sandeep@outlook.com"

DATE_FOLDER=$(date +%Y%m%d)

# Build the S3 destination path with the tenant code and date folder.
S3_DEST="s3://${TENANT_CD}-jupyterhub-emr/jupyter_home_custom_backup/${DATE_FOLDER}"

# ------------------------------------------------------
# Function: Send an error email with a message.
# ------------------------------------------------------
send_error_email() {
  local message="$1"
  echo "$message" | mail -s "HIGH PRIORITY: JupyterHub Backup Failure" "$ADMIN_EMAIL"
}

check_status() {
  local status=$1
  local step="$2"
  if [ $status -ne 0 ]; then
    local error_msg="[$(date)] ERROR during '${step}' step. Exiting backup sync script."
    echo "$error_msg" >> "$LOG_FILE"
    send_error_email "$error_msg"
    exit $status
  fi
}

# ------------------------------------------------------
# Main Section: Perform the backup process.
# ------------------------------------------------------
{
  echo "[$(date)] Starting backup sync for tenant: ${TENANT_CD}"

  echo "[$(date)] Creating backup folder inside the container..."
  sudo docker exec jupyterhub bash -c "mkdir -p /etc/jupyter/jupy_home_bkp"
  check_status $? "creating backup folder"

  echo "[$(date)] Copying the /home directory to the backup folder..."
  sudo docker exec jupyterhub bash -c "cp -r /home /etc/jupyter/jupy_home_bkp"
  check_status $? "copying /home directory"


  echo "[$(date)] Uploading backup to S3 at ${S3_DEST}..."
  aws s3 sync --sse AES256 /etc/jupyter/jupy_home_bkp "${S3_DEST}/"
  check_status $? "uploading backup to S3"

  echo "[$(date)] Removing the backup folder from the container..."
  sudo docker exec jupyterhub bash -c "rm -r /etc/jupyter/jupy_home_bkp"
  check_status $? "removing backup folder"

  echo "[$(date)] Backup sync complete for tenant: ${TENANT_CD}"
} >> "$LOG_FILE" 2>&1
