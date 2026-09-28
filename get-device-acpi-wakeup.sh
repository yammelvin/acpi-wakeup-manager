#!/bin/bash
set -euo pipefail

OUTPUT_FILE="${1:-device-acpi-wakeup.cfg}"
PCI_DEVICES_DIR="/sys/bus/pci/devices"

# Clear or create the output file
: > "$OUTPUT_FILE"

for dev_dir in "$PCI_DEVICES_DIR"/*; do
  wakeup_file="$dev_dir/power/wakeup"
  if [ -f "$wakeup_file" ]; then
    dev_id=$(basename "$dev_dir")
    status=$(cat "$wakeup_file")
    desc=$(lspci -D -s "$dev_id" 2>/dev/null | cut -d' ' -f2- || true)
    if [ -n "$desc" ]; then
      printf "%s %s # %s\n" "$dev_id" "$status" "$desc" >> "$OUTPUT_FILE"
    else
      printf "%s %s\n" "$dev_id" "$status" >> "$OUTPUT_FILE"
    fi
  fi
done

