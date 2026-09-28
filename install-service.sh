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

echo "=== Installing ACPI Wakeup Manager ==="

# 1. Run the get script to generate the config file
echo "Step 1: Generating wakeup configuration at $CONFIG_FILE..."
"$SCRIPT_DIR/get-device-acpi-wakeup.sh" "$CONFIG_FILE"

# Preserve original user ownership if invoked with sudo
if [ -n "${SUDO_USER:-}" ]; then
  chown "${SUDO_USER}:${SUDO_GID:-$(id -g "$SUDO_USER")}" "$CONFIG_FILE" 2>/dev/null || true
fi

# 2. Overwrite/install the service file into /etc/systemd/system/
echo "Step 2: Installing/overwriting $SERVICE_NAME at $SERVICE_DEST..."
install -m 0644 "$SCRIPT_DIR/$SERVICE_NAME" "$SERVICE_DEST"

# 3. Modify WorkingDirectory and ExecStart (and ConditionPathExists) in the installed service file
echo "Step 3: Configuring paths in $SERVICE_DEST..."
sed -i "s|^WorkingDirectory=.*|WorkingDirectory=${SCRIPT_DIR}|" "$SERVICE_DEST"
sed -i "s|^ExecStart=.*|ExecStart=${SCRIPT_DIR}/set-device-acpi-wakeup.sh ${CONFIG_FILE}|" "$SERVICE_DEST"
sed -i "s|^ConditionPathExists=.*|ConditionPathExists=${CONFIG_FILE}|" "$SERVICE_DEST"

# 4. Reload systemd, re-enable with --force to overwrite existing symlinks, and run now
echo "Step 4: Reloading systemd and enabling service (overriding existing)..."
systemctl daemon-reload
systemctl enable --force --now "$SERVICE_NAME"

echo "=== Installation complete ==="
systemctl status "$SERVICE_NAME" --no-pager || true
