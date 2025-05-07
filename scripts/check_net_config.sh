#!/bin/bash

# Check if a host list file was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <host_list_file>"
  exit 1
fi

HOST_FILE="$1"
SSH_USER="core"

if [ ! -f "$HOST_FILE" ]; then
  echo "Error: Host file '$HOST_FILE' not found."
  exit 1
fi

echo "Checking network configuration for hosts listed in '$HOST_FILE'..."
echo "--------------------------------------------------"

# Open the host file on file descriptor 3
exec 3< "$HOST_FILE"

# Read hostnames from the file using file descriptor 3
while IFS= read -r host <&3
do
  # Skip empty lines or lines starting with #
  if [[ -z "$host" || "$host" =~ ^# ]]; then
    continue
  fi

  echo "Connecting to $host..."
  echo "--- Default Gateway (ip route show default) ---"
  # Execute command to show default route via SSH
  ssh -i ~/redhat-demo-openssh-new\ 1 "${SSH_USER}@${host}" 'ip route show default'
  if [ $? -ne 0 ]; then
    echo "Error: Could not get default route from $host via SSH."
    echo "Please ensure SSH access is configured for user '${SSH_USER}' to ${host}."
  fi
  echo "" # Add a blank line for separation

  echo "--- DNS Configuration (cat /etc/resolv.conf) ---"
  # Execute command to show resolv.conf via SSH
  ssh -i ~/redhat-demo-openssh-new\ 1 "${SSH_USER}@${host}" 'cat /etc/resolv.conf'
  if [ $? -ne 0 ]; then
    echo "Error: Could not get resolv.conf from $host via SSH."
    echo "Please ensure SSH access is configured for user '${SSH_USER}' to ${host}."
  fi
  echo "" # Add a blank line for separation

  echo "--------------------------------------------------"

done

# Close file descriptor 3
exec 3<&-

echo "Network configuration check complete."
