#!/bin/bash
set -euo pipefail

# Ensure script is run with root privileges
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Error: This uninstall script requires root privileges. Please run with sudo:" >&2
  echo "  sudo $0" >&2
  exit 1
fi

SERVICE_NAME="set-device-acpi-wakeup.service"
SERVICE_DEST="/etc/systemd/system/$SERVICE_NAME"

echo "=== Uninstalling ACPI Wakeup Manager Service ==="

# 1. Stop the service if active
echo "Step 1: Stopping $SERVICE_NAME..."
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
  systemctl stop "$SERVICE_NAME"
else
  echo "  $SERVICE_NAME is not active, skipping."
fi

# 2. Disable the service if enabled
echo "Step 2: Disabling $SERVICE_NAME..."
if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
  systemctl disable "$SERVICE_NAME"
else
  echo "  $SERVICE_NAME is not enabled, skipping."
fi

# 3. Remove the installed service file from /etc/systemd/system/
echo "Step 3: Removing $SERVICE_DEST..."
if [ -f "$SERVICE_DEST" ] || [ -L "$SERVICE_DEST" ]; then
  rm -f "$SERVICE_DEST"
else
  echo "  $SERVICE_DEST not found, skipping."
fi

# 4. Reload systemd daemon to pick up the changes and clear failed states
echo "Step 4: Reloading systemd daemon..."
systemctl daemon-reload
systemctl reset-failed 2>/dev/null || true

echo "=== Uninstallation complete ==="

