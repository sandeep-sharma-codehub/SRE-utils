#!/bin/bash

# Read server details from CSV file
CSV_FILE="servers.csv"

if [ ! -f "$CSV_FILE" ]; then
  echo "CSV file $CSV_FILE not found!"
  exit 1
fi

# Skip the header and read each line
while IFS=, read -r HOST IP USER PASS; do
  # Skip header line
  if [[ "$HOST" == "hostname" ]]; then
    continue
  fi
  echo "🔐 Connecting to $HOST ($IP) as $USER"

  sshpass -p "$PASS" ssh -tt -o StrictHostKeyChecking=no "$USER@$IP" <<EOF
echo "$PASS" | sudo -S yum install -y cronie
echo "$PASS" | sudo -S systemctl enable crond
echo "$PASS" | sudo -S systemctl start crond
( sudo crontab -l 2>/dev/null; echo "*/5 * * * * echo hello > /tmp/cron_text" ) | sudo crontab -
exit
EOF

  if [ $? -eq 0 ]; then
    echo "✅ Task completed on $HOST"
  else
    echo "❌ Failed on $HOST"
  fi
done < "$CSV_FILE"
