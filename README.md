# ACPI Wakeup Tools

Contain bash scripts and systemd service to store, configure, and persist ACPI wakeup states for PCI devices on Linux systems.

## Purpose

By default on many Linux systems, various PCI devices (such as USB host controllers, Ethernet adapters, sound cards, and PCI bridges) have ACPI wakeup enabled in `/sys/bus/pci/devices/<id>/power/wakeup`. These wakeup triggers can cause your computer to wake up unexpectedly from sleep/suspend (e.g., due to background USB activity, network packets, or mouse movements).

Because Linux kernel `/sys` power wakeup states reset upon reboot, this project provides:
- Bash scripts to discover and record current PCI device wakeup states in a simple, editable configuration file.
- A systemd service to automatically apply these wakeup states at boot time.
- Bash scripts to install and uninstall the systemd service.

---

## Manual Usage

### 1. Generating or Updating the Configuration

To inspect all PCI devices and output their current wakeup settings to a file:

```bash
# Writes to default device-acpi-wakeup.cfg
./get-device-acpi-wakeup.sh

# Or specify a custom output file
./get-device-acpi-wakeup.sh custom-wakeup.cfg
```

This reads `/sys/bus/pci/devices/*/power/wakeup`, queries `lspci` for device descriptions, and writes the results.

### 2. Applying Configuration States

To apply the settings from the configuration file to your system's PCI devices:

```bash
# Uses default device-acpi-wakeup.cfg
sudo ./set-device-acpi-wakeup.sh

# Or specify a custom configuration file
sudo ./set-device-acpi-wakeup.sh custom-wakeup.cfg
```

> **Note:** Writing to `/sys/bus/pci/devices/<id>/power/wakeup` requires root permissions, which is why `sudo` is required.

---

## Installation & Setup

### 1. Install the Service

Run the installation script with `sudo`:

```bash
# Uses default device-acpi-wakeup.cfg
sudo ./install-service.sh

# Or specify a custom configuration file
sudo ./install-service.sh custom-wakeup.cfg
```

What this script does:
1. Executes `get-device-acpi-wakeup.sh` to generate/refresh the configuration file with the current system state.
2. Copies `set-device-acpi-wakeup.service` to `/etc/systemd/system/`.
3. Dynamically configures `WorkingDirectory`, `ExecStart`, and `ConditionPathExists` paths to point to this directory and the configuration file.
4. Reloads the systemd daemon, enables the service to run at boot (`multi-user.target`), and runs it immediately.

### 2. Configure Wakeup States

Open `device-acpi-wakeup.cfg` in your preferred text editor:

```bash
nano device-acpi-wakeup.cfg
```

Each line adheres to the format:
```text
<PCI_DEVICE_ID> <enabled|disabled>
```

Change the state to `enabled` or `disabled` for any device as needed, then save the file.

To apply changes immediately after editing:
```bash
sudo systemctl restart set-device-acpi-wakeup.service
```

---

## Uninstallation

To remove the systemd service, run:

```bash
sudo ./uninstall-service.sh
```

What this script does:
1. Stops `set-device-acpi-wakeup.service` if active.
2. Disables the service from starting at boot.
3. Removes `/etc/systemd/system/set-device-acpi-wakeup.service`.
4. Reloads the systemd daemon and resets failed unit states.

> **Note:** The local script files and `device-acpi-wakeup.cfg` in this directory are preserved.
