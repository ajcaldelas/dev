#!/bin/bash

# --- Configuration ---

# List of servers/BMCs to shut down (only the 'xcc-' hostnames).
# IMPORTANT: These should ideally be the BMC IP addresses or hostnames,
# not the server OS hostnames, unless your network/DNS is configured
# to resolve server names to BMC interfaces for IPMI.
SERVERS=(
    "xcc-7d9a-J1050MC1.amd.com"
    "xcc-7d9a-J1050MBL.amd.com"
    "xcc-7d9a-J1050MBB.amd.com"
    "xcc-7d9a-J1050MBA.amd.com"
    "xcc-7d76-JZ001CLD.amd.com"
)

# IPMI interface type (lanplus is common for modern systems)
IPMI_INTERFACE="lanplus"

# --- Security Warning & Credential Handling ---
# IMPORTANT: Do NOT hardcode your IPMI username and password here.
# This script relies on the IPMI_USER and IPMI_PASSWORD environment variables.
# Set them in your terminal BEFORE running the script:
# export IPMI_USER="your_ipmi_username"
# export IPMI_PASSWORD="your_ipmi_password"
# Or run the script like this:
# IPMI_USER="your_username" IPMI_PASSWORD="your_password" ./your_script_name.sh

IPMI_USER="${IPMI_USER}"
IPMI_PASSWORD="${IPMI_PASSWORD}"

# Check if credentials environment variables are set
if [ -z "$IPMI_USER" ] || [ -z "$IPMI_PASSWORD" ]; then
    echo "ERROR: IPMI_USER and IPMI_PASSWORD environment variables must be set."
    echo "Please set them before running the script."
    echo "Example: export IPMI_USER='your_username' && export IPMI_PASSWORD='your_password'"
    exit 1
fi

# --- Function to install ipmitool ---
install_ipmitool() {
    echo "ipmitool not found."
    echo "Attempting to install ipmitool. This may require sudo access."

    # Detect package manager
    if command -v apt &> /dev/null; then
        # Debian/Ubuntu based
        echo "Detected apt package manager."
        sudo apt update && sudo apt install -y ipmitool
        if [ $? -eq 0 ]; then
            echo "ipmitool installed successfully using apt."
        else
            echo "ERROR: Failed to install ipmitool using apt. Please install it manually."
            exit 1
        fi
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS/Fedora based (older)
        echo "Detected yum package manager."
        sudo yum install -y ipmitool
         if [ $? -eq 0 ]; then
            echo "ipmitool installed successfully using yum."
        else
            echo "ERROR: Failed to install ipmitool using yum. Please install it manually."
            exit 1
        fi
    elif command -v dnf &> /dev/null; then
         # Fedora/RHEL 8+ based
        echo "Detected dnf package manager."
        sudo dnf install -y ipmitool
         if [ $? -eq 0 ]; then
            echo "ipmitool installed successfully using dnf."
        else
            echo "ERROR: Failed to install ipmitool using dnf. Please install it manually."
            exit 1
        fi
    else
        echo "ERROR: Could not detect a supported package manager (apt, yum, or dnf)."
        echo "Please install ipmitool manually on this system."
        exit 1
    fi

    # Verify installation
    if ! command -v ipmitool &> /dev/null; then
        echo "ERROR: ipmitool installation failed verification. Command still not found."
        exit 1
    fi
}

# --- Main Script Logic ---

# Check if ipmitool is installed
if ! command -v ipmitool &> /dev/null; then
    install_ipmitool
else
    echo "ipmitool found at: $(command -v ipmitool)"
fi

echo "Starting server shutdown process for the following servers:"
for server in "${SERVERS[@]}"; do
    echo "- $server"
done
echo "---"

# Loop through servers and shut them down
for server in "${SERVERS[@]}"; do
    echo "Attempting to shut down: $server"

    # Construct the ipmitool command
    # Using -P directly is necessary for lanplus interface, but less secure.
    # Ensure this script is run from a trusted environment.
    IPMI_CMD="ipmitool -I ${IPMI_INTERFACE} -H ${server} -U ${IPMI_USER} -P ${IPMI_PASSWORD} power off"

    # Execute the command
    # We redirect stderr to /dev/null to suppress common IPMI warnings/errors unless the command truly fails
    if $IPMI_CMD &> /dev/null; then
        echo "SUCCESS: Shutdown command sent to $server."
    else
        echo "FAILURE: Could not send shutdown command to $server. Check hostname/IP, credentials, network connectivity, and server state."
        # You might want to run the command without > /dev/null to see the exact error message from ipmitool
        # For example: ipmitool -I ${IPMI_INTERFACE} -H ${server} -U ${IPMI_USER} -P ${IPMI_PASSWORD} power off
    fi
    echo "---" # Separator for readability
done

echo "Shutdown process complete."

exit 0
