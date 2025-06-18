#!/bin/bash

# --- Configuration ---

# List of servers/BMCs (XCC) to clean up.
# This list is only for lenovo boxes
# Use the same list as your boot script.
SERVERS=(
    "xcc-7d9a-J1050MC1.amd.com"
    "xcc-7d9a-J1050MBL.amd.com"
    "xcc-7d9a-J1050MBB.amd.com"
    "xcc-7d9a-J1050MBA.amd.com"
    "xcc-7d76-JZ001CLD.amd.com"
)

# Redfish Paths (using discovered paths)
# This is the path to the specific Virtual Media device (EXT1) that supports CD.
# We identified EXT1 as the device listing CD support.
# If you had reason to prefer Remote1, you could use "/redfish/v1/Managers/1/VirtualMedia/Remote1" instead.
REDFISH_VIRTUAL_MEDIA_CD_PATH="/redfish/v1/Managers/1/VirtualMedia/EXT1"

# This is the path to the standard ComputerSystem.Reset action for shutdown.
# We avoid the OEM action used for PowerCycle during boot.
REDFISH_SYSTEM_ACTION_RESET="/redfish/v1/Systems/1/Actions/ComputerSystem.Reset"

# Payloads
# Payload to eject virtual media - set Inserted to false and Image to null.
EJECT_PAYLOAD='{"Inserted": false, "Image": null}'

# Payload for shutdown.
# "GracefulShutdown" requests the OS to shut down cleanly. This is preferred for cleanup.
# Use "ForceOff" if you need an immediate power cut regardless of OS state
# (e.g., if the OS is not responsive for a graceful shutdown).
SHUTDOWN_PAYLOAD='{"ResetType": "GracefulShutdown"}'
# If you need ForceOff, uncomment the line below and comment the one above:
# SHUTDOWN_PAYLOAD='{"ResetType": "ForceOff"}'


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

if [ -z "$REDFISH_USER" ] || [ -z "$REDFISH_PASSWORD" ]; then
    echo "ERROR: REDFISH_USER and REDFISH_PASSWORD environment variables must be set."
    echo "Please set them before running the script."
    echo "Example: export REDFISH_USER='your_username' && export REDFISH_PASSWORD='your_password'"
    exit 1
fi

# --- Function to install curl ---
# (Same function as in the previous script)
install_curl() {
    echo "curl not found. Attempting to install..."
    if command -v apt &> /dev/null; then sudo apt update && sudo apt install -y curl; elif command -v yum &> /dev/null; then sudo yum install -y curl; elif command -v dnf &> /dev/null; then sudo dnf install -y curl; else echo "ERROR: Could not detect supported package manager (apt, yum, dnf). Please install curl manually."; exit 1; fi
    if ! command -v curl &> /dev/null; then echo "ERROR: curl installation failed verification."; exit 1; fi
    echo "curl installed successfully."
}


# --- Main Script Logic ---

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    install_curl
else
    echo "curl found at: $(command -v curl)"
fi

echo "Starting server cleanup process (eject VM, shutdown)..."

# Loop through servers
for server in "${SERVERS[@]}"; do
    echo "--- Cleaning up $server ---"

    # --- Step 1: Eject Virtual Media ---
    # We use the PATCH method on the specific VirtualMedia device resource.
    echo "Attempting to eject virtual media from ${REDFISH_VIRTUAL_MEDIA_CD_PATH}..."
    REDFISH_VM_URL="https://${server}${REDFISH_VIRTUAL_MEDIA_CD_PATH}"
    # -k: Allows insecure server connections (for self-signed certs)
    # -u user:pass: Provides username and password for Basic Authentication
    # -X PATCH: Specifies the HTTP PATCH method
    # -H "Content-Type: application/json": Sets the request header
    # -d <payload>: Sends the specified data as the request body
    # -s: Silent mode (don't show progress or error messages unless curl fails)
    # -o /dev/null: Discard the output response body from the server
    # --write-out "%{http_code}": Print the HTTP status code after the transfer
    HTTP_STATUS=$(curl -k \
                       -u "${REDFISH_USER}:${REDFISH_PASSWORD}" \
                       -X PATCH \
                       -H "Content-Type: application/json" \
                       -d "${EJECT_PAYLOAD}" \
                       -s -o /dev/null --write-out "%{http_code}" \
                       "${REDFISH_VM_URL}")

    # Check the exit status of curl AND the HTTP status code from the Redfish service (2xx indicates success)
    if [ $? -eq 0 ] && [[ "$HTTP_STATUS" =~ ^2 ]]; then
        echo "SUCCESS: Virtual media ejected (HTTP Status: $HTTP_STATUS)."
    else
        echo "FAILURE: Could not eject virtual media (HTTP Status: $HTTP_STATUS). Check VM path (${REDFISH_VIRTUAL_MEDIA_CD_PATH}), credentials, network."
        # We continue to shutdown attempt even if eject fails, as shutdown is the primary goal
    fi

    # --- Step 2: Shut Down Server ---
    # We use the standard Redfish ComputerSystem.Reset action with GracefulShutdown or ForceOff.
    # This is different from the OEM action used for power cycling during boot.
    echo "Attempting to shut down server..."
    REDFISH_SHUTDOWN_URL="https://${server}${REDFISH_SYSTEM_ACTION_RESET}"
     HTTP_STATUS=$(curl -k \
                       -u "${REDFISH_USER}:${REDFISH_PASSWORD}" \
                       -X POST \
                       -H "Content-Type: application/json" \
                       -d "${SHUTDOWN_PAYLOAD}" \
                       -s -o /dev/null --write-out "%{http_code}" \
                       "${REDFISH_SHUTDOWN_URL}")

    # Check the exit status of curl AND the HTTP status code from the Redfish service (2xx indicates success)
    if [ $? -eq 0 ] && [[ "$HTTP_STATUS" =~ ^2 ]]; then
        echo "SUCCESS: Shutdown command sent (HTTP Status: $HTTP_STATUS)."
    else
        echo "FAILURE: Could not send shutdown command (HTTP Status: $HTTP_STATUS). Check Reset action path (${REDFISH_SYSTEM_ACTION_RESET}), payload (${SHUTDOWN_PAYLOAD}), credentials."
    fi

    echo "---" # Separator for readability

done

echo "Cleanup process complete."

exit 0
