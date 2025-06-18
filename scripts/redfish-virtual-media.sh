#!/bin/bash

# --- Configuration ---

# List of servers/BMCs (XCC) to configure.
SERVERS=(
    "xcc-7d9a-J1050MC1.amd.com"
    "xcc-7d9a-J1050MBL.amd.com"
    "xcc-7d9a-J1050MBB.amd.com"
    "xcc-7d9a-J1050MBA.amd.com"
    "xcc-7d76-JZ001CLD.amd.com"
)

# Full HTTP URL to the ISO file
ISO_URL="http://10.216.188.48:8080/ocp_iso/agent.x86_64.iso"

# Redfish Paths (assuming common Lenovo XCC structure)
# You might need to discover Manager ID and VirtualMedia ID if these don't work.
REDFISH_MANAGER_PATH="/redfish/v1/Managers/1" # Common Manager ID is gXT1
gEDFISH_VIRTUAL_MEDIA_CD_PATH="${REDFISH_MANAGER_PATH}/VirtualMedia/EXT1" # Common Virtual CD ID is 1
REDFISH_SYSTEM_PATH="/redfish/v1/Systems/1" # Verified System ID is 1

# Redfish Boot Source Target for Virtual CD (common value is "Cd")
# Could potentially be "CDROM" or other vendor-specific strings.
BOOT_SOURCE_TARGET="Cd"

# --- Security Warning & Credential Handling ---
REDFISH_USER="${REDFISH_USER}"
REDFISH_PASSWORD="${REDFISH_PASSWORD}"

if [ -z "$REDFISH_USER" ] || [ -z "$REDFISH_PASSWORD" ]; then
    echo "ERROR: REDFISH_USER and REDFISH_PASSWORD environment variables must be set."
    echo "Please set them before running the script."
    echo "Example: export REDFISH_USER='your_username' && export REDFISH_PASSWORD='your_password'"
    exit 1
fi

# --- Function to install curl ---
install_curl() {
    echo "curl not found. Attempting to install..."
    # (Same install_curl function as in the previous script)
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

echo "Starting virtual media mount and boot configuration process..."

# Loop through servers
for server in "${SERVERS[@]}"; do
    echo "--- Configuring $server ---"

    # --- Step 1: Mount the ISO via Virtual Media ---
    echo "Attempting to mount virtual media ISO: ${ISO_URL}"
    REDFISH_VM_URL="https://${server}${REDFISH_VIRTUAL_MEDIA_CD_PATH}"
    # Payload to set Image URL and mark as Inserted and Write Protected
    VM_PAYLOAD='{"Image": "'"${ISO_URL}"'", "Inserted": true, "WriteProtected": true}'

    HTTP_STATUS=$(curl -k \
                       -u "${REDFISH_USER}:${REDFISH_PASSWORD}" \
                       -X PATCH \
                       -H "Content-Type: application/json" \
                       -d "${VM_PAYLOAD}" \
                       -s -o /dev/null --write-out "%{http_code}" \
                       "${REDFISH_VM_URL}")

    if [ $? -eq 0 ] && [[ "$HTTP_STATUS" =~ ^2 ]]; then
        echo "SUCCESS: Virtual media mounted (HTTP Status: $HTTP_STATUS)."
    else
        echo "FAILURE: Could not mount virtual media (HTTP Status: $HTTP_STATUS). Check VM path (${REDFISH_VIRTUAL_MEDIA_CD_PATH}), credentials, network."
        echo "Skipping boot configuration and reset for this server."
        echo "---"
        continue # Skip to the next server if mounting fails
    fi

    # --- Step 2: Set One-Time Boot Order to Virtual CD ---
    echo "Attempting to set one-time boot order to Virtual CD (${BOOT_SOURCE_TARGET})."
    REDFISH_BOOT_URL="https://${server}${REDFISH_SYSTEM_PATH}"
    # Payload to set one-time boot override to the CD device
    # Assumes BootSourceOverrideTarget "Cd" is correct
    BOOT_PAYLOAD='{"Boot": {"BootSourceOverrideTarget": "'"${BOOT_SOURCE_TARGET}"'", "BootSourceOverrideEnabled": "Once"}}'

     HTTP_STATUS=$(curl -k \
                       -u "${REDFISH_USER}:${REDFISH_PASSWORD}" \
                       -X PATCH \
                       -H "Content-Type: application/json" \
                       -d "${BOOT_PAYLOAD}" \
                       -s -o /dev/null --write-out "%{http_code}" \
                       "${REDFISH_BOOT_URL}")

    if [ $? -eq 0 ] && [[ "$HTTP_STATUS" =~ ^2 ]]; then
        echo "SUCCESS: Boot order set (HTTP Status: $HTTP_STATUS)."
    else
        echo "FAILURE: Could not set boot order (HTTP Status: $HTTP_STATUS). Check System path (${REDFISH_SYSTEM_PATH}), BootSourceOverrideTarget ('${BOOT_SOURCE_TARGET}'), credentials."
         echo "Skipping reset for this server."
         echo "---"
        continue # Skip to the next server if boot order fails
    fi


    # --- Step 3: Reset / Power Cycle the System to Apply Boot Order ---
    echo "Attempting to reset the server to boot from virtual media."
#    REDFISH_RESET_URL="https://${server}/redfish/v1/Systems/1/Actions/Oem/LenovoComputerSystem.SystemReset" # Correct OEM action path
    REDFISH_RESET_URL="https://${server}${REDFISH_SYSTEM_PATH}/Actions/ComputerSystem.Reset"
    # Use ForceRestart or GracefulRestart
#    RESET_PAYLOAD='{"ResetType": "ACPowerCycle"}' # Correct payload for OEM action
#    RESET_PAYLOAD='{"ResetType": "ForceRestart"}' # Or "GracefulRestart" if preferred
    RESET_PAYLOAD='{"ResetType": "On"}' # Or "On"

    HTTP_STATUS=$(curl -k \
                       -u "${REDFISH_USER}:${REDFISH_PASSWORD}" \
                       -X POST \
                       -H "Content-Type: application/json" \
                       -d "${RESET_PAYLOAD}" \
                       -s -o /dev/null --write-out "%{http_code}" \
                       "${REDFISH_RESET_URL}")

    if [ $? -eq 0 ] && [[ "$HTTP_STATUS" =~ ^2 ]]; then
        echo "SUCCESS: Reset command sent (HTTP Status: $HTTP_STATUS). Server should boot from ISO."
    else
        echo "FAILURE: Could not send reset command (HTTP Status: $HTTP_STATUS). Check Reset path (${REDFISH_SYSTEM_PATH}/Actions/ComputerSystem.Reset), credentials."
    fi

    echo "---"

done

echo "Virtual media configuration process complete."

exit 0
