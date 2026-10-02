#!/bin/bash
set -euo pipefail

# Ensure script is run with root privileges
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Error: This install script requires root privileges. Please run with sudo:" >&2
  echo "  sudo $0 [CONFIG_FILE]" >&2
  exit 1
fi

SCRIPT_DIR="$(dirname "$(realpath -- "${BASH_SOURCE[0]}")")"
SERVICE_NAME="set-device-acpi-wakeup.service"
SERVICE_DEST="/etc/systemd/system/$SERVICE_NAME"
CONFIG_FILE="$(realpath -- "${1:-device-acpi-wakeup.cfg}")"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file $CONFIG_FILE does not exist." >&2
  exit 1
fi

echo CONFIG_FILE="$CONFIG_FILE"

echo "=== Installing ACPI Wakeup Manager ==="

# Install the service file into /etc/systemd/system/
echo "Installing $SERVICE_NAME at $SERVICE_DEST..."
install -m 0644 "$SCRIPT_DIR/$SERVICE_NAME" "$SERVICE_DEST"

# Modify WorkingDirectory and ExecStart (and ConditionPathExists) in the installed service file
echo "Configuring paths in $SERVICE_DEST..."
sed -i "s|^WorkingDirectory=.*|WorkingDirectory=${SCRIPT_DIR}|" "$SERVICE_DEST"
sed -i "s|^ExecStart=.*|ExecStart=${SCRIPT_DIR}/set-device-acpi-wakeup.sh ${CONFIG_FILE}|" "$SERVICE_DEST"
sed -i "s|^ConditionPathExists=.*|ConditionPathExists=${CONFIG_FILE}|" "$SERVICE_DEST"

# Reload systemd, re-enable with --force to overwrite existing symlinks, and run now
echo "Reloading systemd and enabling service (overriding existing)..."
systemctl daemon-reload
systemctl enable --force --now "$SERVICE_NAME"

echo "=== Installation complete ==="
systemctl status "$SERVICE_NAME" --no-pager || true
