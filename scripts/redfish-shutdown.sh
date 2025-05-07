#!/bin/bash

# --- Configuration ---

# List of servers/BMCs to shut down (using Redfish endpoint addresses).
# Ensure these are the correct IP addresses or hostnames for your BMCs (XCC).
SERVERS=(
    "xcc-7d9a-J1050MC1.amd.com"
    "xcc-7d9a-J1050MBL.amd.com"
    "xcc-7d9a-J1050MBB.amd.com"
    "xcc-7d9a-J1050MBA.amd.com"
    "xcc-7d76-JZ001CLD.amd.com"
)

# Redfish power action endpoint path
# System.Embedded.1 is a common System ID. You might need to discover
# the correct ID if this does not work for your servers.
REDFISH_SYSTEM_PATH="/redfish/v1/Systems/1"
REDFISH_ACTION_PATH="${REDFISH_SYSTEM_PATH}/Actions/ComputerSystem.Reset" # Standard path for power actions

# The specific reset type for shutdown (PowerOff is immediate)
# Alternatives include GracefulShutdown, ForceOff, etc.
REDFISH_RESET_TYPE="ForceOff"

# --- Security Warning & Credential Handling ---
# IMPORTANT: Do NOT hardcode your Redfish username and password here.
# This script relies on the REDFISH_USER and REDFISH_PASSWORD environment variables.
# Set them in your terminal BEFORE running the script:
# export REDFISH_USER="your_redfish_username"
# export REDFISH_PASSWORD="your_redfish_password"
# Or run the script like this:
# REDFISH_USER="your_username" REDFISH_PASSWORD="your_password" ./your_script_name.sh

REDFISH_USER="${REDFISH_USER}"
REDFISH_PASSWORD="${REDFISH_PASSWORD}"

# Check if credentials environment variables are set
if [ -z "$REDFISH_USER" ] || [ -z "$REDFISH_PASSWORD" ]; then
    echo "ERROR: REDFISH_USER and REDFISH_PASSWORD environment variables must be set."
    echo "Please set them before running the script."
    echo "Example: export REDFISH_USER='your_username' && export REDFISH_PASSWORD='your_password'"
    exit 1
fi

# --- Function to install curl ---
install_curl() {
    echo "curl not found."
    echo "Attempting to install curl. This may require sudo access."

    # Detect package manager
    if command -v apt &> /dev/null; then
        # Debian/Ubuntu based
        echo "Detected apt package manager."
        sudo apt update && sudo apt install -y curl
        if [ $? -eq 0 ]; then
            echo "curl installed successfully using apt."
        else
            echo "ERROR: Failed to install curl using apt. Please install it manually."
            exit 1
        fi
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS/Fedora based (older)
        echo "Detected yum package manager."
        sudo yum install -y curl
         if [ $? -eq 0 ]; then
            echo "curl installed successfully using yum."
        else
            echo "ERROR: Failed to install curl using yum. Please install it manually."
            exit 1
        fi
    elif command -v dnf &> /dev/null; then
         # Fedora/RHEL 8+ based
        echo "Detected dnf package manager."
        sudo dnf install -y curl
         if [ $? -eq 0 ]; then
            echo "curl installed successfully using dnf."
        else
            echo "ERROR: Failed to install curl using dnf. Please install it manually."
            exit 1
        fi
    else
        echo "ERROR: Could not detect a supported package manager (apt, yum, or dnf)."
        echo "Please install curl manually on this system."
        exit 1
    fi

    # Verify installation
    if ! command -v curl &> /dev/null; then
        echo "ERROR: curl installation failed verification. Command still not found."
        exit 1
    fi
}


# --- Main Script Logic ---

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    install_curl
else
    echo "curl found at: $(command -v curl)"
fi


echo "Starting server shutdown process using Redfish..."

# Loop through servers and send Redfish shutdown command
for server in "${SERVERS[@]}"; do
    echo "Attempting to shut down: $server using Redfish..."

    # Construct the Redfish shutdown URL
    REDFISH_URL="https://${server}${REDFISH_ACTION_PATH}"

    # Construct the JSON payload for the shutdown action
    REDFISH_PAYLOAD='{"ResetType": "'"${REDFISH_RESET_TYPE}"'"}'

    # --- Execute the curl command ---
    # -k / --insecure: Allows insecure server connections (useful for self-signed certs)
    # -u user:pass: Provides username and password for Basic Authentication
    # -X POST: Specifies the HTTP POST method
    # -H "Content-Type: application/json": Sets the request header
    # -d <payload>: Sends the specified data as the request body
    # -s: Silent mode (don't show progress or error messages unless curl fails)
    # -o /dev/null: Discard the output response body from the server
    # --write-out "%{http_code}": Print the HTTP status code after the transfer
    # The http_code is checked to see if the Redfish request was likely successful (e.g., 200, 202, 204)

    HTTP_STATUS=$(curl -k \
                       -u "${REDFISH_USER}:${REDFISH_PASSWORD}" \
                       -X POST \
                       -H "Content-Type: application/json" \
                       -d "${REDFISH_PAYLOAD}" \
                       -s \
                       -o /dev/null \
                       --write-out "%{http_code}" \
                       "${REDFISH_URL}")

    # Check the exit status of curl AND the HTTP status code from the Redfish service
    # 0 is curl success; 2xx usually indicates Redfish action accepted/successful
    if [ $? -eq 0 ] && [[ "$HTTP_STATUS" =~ ^2 ]]; then
        echo "SUCCESS: Shutdown command sent to $server (HTTP Status: $HTTP_STATUS)."
    else
        echo "FAILURE: Could not send shutdown command to $server."
        echo "  Curl Exit Code: $?"
        echo "  HTTP Status Received: $HTTP_STATUS"
        echo "  Possible issues: Check hostname/IP, credentials, network, certificate (-k needed?), Redfish path (${REDFISH_ACTION_PATH})."
    fi
    echo "---" # Separator for readability
done

echo "Shutdown process complete."

exit 0
