#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1:-device-acpi-wakeup.cfg}"
PCI_DEVICES_DIR="/sys/bus/pci/devices"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file '$CONFIG_FILE' not found." >&2
  exit 1
fi

while IFS= read -r line || [ -n "$line" ]; do
  # Remove comment portion (everything starting from '#')
  clean_line="${line%%#*}"

  # read automatically trims leading/trailing whitespace and splits on any whitespace
  dev_id=""
  status=""
  read -r dev_id status _ <<< "$clean_line" || true

  # Skip blank lines or lines without both dev_id and status
  if [ -z "$dev_id" ] || [ -z "$status" ]; then
    continue
  fi

  # Only accept "enabled" or "disabled", otherwise do nothing
  if [ "$status" != "enabled" ] && [ "$status" != "disabled" ]; then
    continue
  fi

  wakeup_file="$PCI_DEVICES_DIR/$dev_id/power/wakeup"

  # If device does not exist or does not have power/wakeup, do nothing
  if [ -f "$wakeup_file" ]; then
    echo "$status" > "$wakeup_file" 2>/dev/null || echo "Warning: Failed to set $status for $dev_id (check permissions)" >&2
  fi
done < "$CONFIG_FILE"
