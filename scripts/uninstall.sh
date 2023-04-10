#!/usr/bin/env bash

#
# Uninstallation script for GoBackup for Klipper.
#

# Enable error handling
set -eo pipefail

# Enable script debugging
set -x

# Get the script path.
SCRIPT_PATH="$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"

# Load the utility functions.
source "${SCRIPT_PATH}/util.sh"

## TODO: Implement safe uninstallation of the GoBackup binary and the GoBackup systemd service

# Stop the GoBackup systemd service.
stop_systemd_service

# Disable the GoBackup systemd service.
disable_systemd_service

# Remove the GoBackup systemd service.
if test $(id -u) -eq 0; then
  rm -f /etc/systemd/system/gobackup.service
else
  sudo rm -f /etc/systemd/system/gobackup.service
fi

# Reload the systemd daemon.
reload_systemd

# Remove the GoBackup binary.
if test $(id -u) -eq 0; then
  rm -f /usr/local/bin/gobackup
else
  sudo rm -f /usr/local/bin/gobackup
fi

# Remove the GoBackup configuration files.
# rm -fr ~/.gobackup

# Remove the GoBackup source code.
# rm -fr ~/gobackup

echo "Successfully uninstalled GoBackup"
