#!/usr/bin/env bash

## TODO: Since we want to create user specific configuration files and folders, we would never want to run this as root, right?
# Ensure that this script is never ran as root.
if test $(id -u) -eq 0; then
  echo "ERROR: This script should not be run as root" >&2
  exit 1
fi

# Ensure that this script can only be sourced and not ran directly.
if test "${BASH_SOURCE[0]}" = "${0}"; then
  echo "ERROR: This script should be sourced, not ran directly" >&2
  exit 1
fi

# Ensure that we always have a valid user home directory available.
if test -z "${HOME}"; then
  HOME="$(getent passwd $(whoami) | cut -d: -f6)"
fi
if test -z "${HOME}"; then
  echo "ERROR: Could not determine user home directory (is HOME environment variable set?)" >&2
  exit 1
fi

# Function for reloading the systemd daemon and its services.
function reload_systemd() {
  echo "Reloading systemd daemon ..."
  if test $(id -u) -eq 0; then
    systemctl daemon-reload
  else
    sudo systemctl daemon-reload
  fi
}

# Function for enabling a systemd service,
# based on the service name as the first argument.
function enable_systemd_service() {
  echo "Enabling systemd service ${1} ..."
  if test $(id -u) -eq 0; then
    systemctl enable "${1}"
  else
    sudo systemctl enable "${1}"
  fi
}

# Function for disabling a systemd service,
# based on the service name as the first argument.
function disable_systemd_service() {
  echo "Disabling systemd service ${1} ..."
  if test $(id -u) -eq 0; then
    systemctl disable "${1}"
  else
    sudo systemctl disable "${1}"
  fi
}

# Function for starting a systemd service,
# based on the service name as the first argument.
function start_systemd_service() {
  echo "Starting systemd service ${1} ..."
  if test $(id -u) -eq 0; then
    systemctl start "${1}"
  else
    sudo systemctl start "${1}"
  fi
}

# Function for stopping a systemd service,
# based on the service name as the first argument.
function stop_systemd_service() {
  echo "Stopping systemd service ${1} ..."
  if test $(id -u) -eq 0; then
    systemctl stop "${1}"
  else
    sudo systemctl stop "${1}"
  fi
}

# Function for restarting a systemd service,
# based on the service name as the first argument.
function restart_systemd_service() {
  echo "Restarting systemd service ${1} ..."
  if test $(id -u) -eq 0; then
    systemctl restart "${1}"
  else
    sudo systemctl restart "${1}"
  fi
}
