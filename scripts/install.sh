#!/usr/bin/env bash

#
# Installation script for GoBackup for Klipper.
#
# Based loosely on the following files/projects:
# - https://github.com/gobackup/gobackup/blob/main/install
# - https://github.com/eliteSchwein/mooncord/blob/master/scripts/install.sh
#

# Enable error handling.
set -eo pipefail

# Enable script debugging.
# set -x

# Get the script path.
SCRIPT_PATH="$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"

# Define global variables.
GOBACKUP_REPOSITORY="gobackup/gobackup"
GOBACKUP_VERSION="2.0.1"
GOBACKUP_BINARY="gobackup"
GOBACKUP_PLATFORM="$(uname | tr "[A-Z]" "[a-z]")"
GOBACKUP_ARCHITECTURE="$(uname -m | sed 's/x86_64/amd64/')"
GOBACKUP_RELEASE_FILENAME="gobackup-${GOBACKUP_PLATFORM}-${GOBACKUP_ARCHITECTURE}.tar.gz"
GOBACKUP_RELEASE_URL="https://github.com/${GOBACKUP_REPOSITORY}/releases/download/${GOBACKUP_VERSION}/${GOBACKUP_RELEASE_FILENAME}"
GOBACKUP_INSTALL_PATH="/usr/local/bin"
GOBACKUP_BINARY_PATH="${GOBACKUP_INSTALL_PATH}/${GOBACKUP_BINARY}"
GOBACKUP_CONFIG_PATH="${HOME}/.gobackup"
GOBACKUP_SERVICE_NAME="gobackup"
GOBACKUP_TEMP_PATH="$(mktemp -d)"

# Setup a signal trap to always clean up when terminating.
trap "cleanup" EXIT

# Function for cleaning up when terminating the script.
function cleanup() {
  # Remove the temporary directory.
  rm -fr ${GOBACKUP_TEMP_PATH}
}

# Load the utility functions.
# source "$(dirname "${BASH_SOURCE[0]}")/util.sh"
source "${SCRIPT_PATH}/util.sh"

# Define the expected printer data path,
# and verify that it exists.
PRINTER_DATA_PATH="${HOME}/printer_data"
if test ! -d "${PRINTER_DATA_PATH}"; then
  echo "ERROR: Printer data path does not exist: ${PRINTER_DATA_PATH}" >&2
  exit 1
fi

# Function for installing or updating the GoBackup binary itself.
function install_gobackup() {
  # Check if GoBackup is already installed.
  if test -e "${GOBACKUP_BINARY_PATH}"; then
    
    echo "GoBackup already installed, checking for updates ..."  

    # Check if GoBackup should be updated
    local gobackup_version="v$("${GOBACKUP_BINARY_PATH}" -v | awk '{print $NF}')"
    if test "${gobackup_version}" = "${GOBACKUP_VERSION}"; then
      echo "GoBackup already up-to-date"
      return
    else
      echo "Updating GoBackup from ${gobackup_version} to ${GOBACKUP_VERSION} ..."
    fi
    
  else
    echo "GoBackup is not installed, installing ..."
  fi
  
  # Switch to the temporary directory.
  cd "${GOBACKUP_TEMP_PATH}"
  
  # Check if the platform and architecture are supported
  # by querying the GoBackup repository for the release file,
  # and checking if the HTTP status code is 200.
  local gobackup_release_url_status_code="$(curl -sSL -o /dev/null -w "%{http_code}" "${GOBACKUP_RELEASE_URL}")"
  if test "${gobackup_release_url_status_code}" != "200"; then
    echo "NOTICE: No pre-package binaries found for ${GOBACKUP_PLATFORM}/${GOBACKUP_ARCHITECTURE}, attempting to build from sources ..." >&2
    
    # Ensure that Go is installed and up-to-date.
    install_go

    # Get the Go binary path.
    local go_binary_path="$(which go)"

    # Download the GoBackup source code.
    echo "Downloading GoBackup source code ..."
    local gobackup_source_path="${HOME}/gobackup"
    if test ! -d "${gobackup_source_path}"; then
      git clone --depth 1 --branch "v${GOBACKUP_VERSION}" "https://github.com/${GOBACKUP_REPOSITORY}.git" "${gobackup_source_path}"
    else
      cd "${gobackup_source_path}"
      git fetch --all --tags --prune
      git reset --hard "v${GOBACKUP_VERSION}"
    fi

    # Install Yarn
    echo "Ensuring yarn is installed ..."
    if ! command -v yarn &> /dev/null; then
      echo "yarn not found, installing ..."
      if test $(id -u) -eq 0; then
        npm install --global yarn
      else
        sudo npm install --global yarn
      fi
    fi

    # Build web assets
    echo "Building web assets ..."
    if test $(id -u) -eq 0; then
      make build_web
    else
      sudo make build_web
    fi

    # Install Go dependencies.
    echo "Installing GoBackup build dependencies ..."
    if test $(id -u) -eq 0; then
      ${go_binary_path} mod download
    else
      sudo ${go_binary_path} mod download
    fi

    # Build the GoBackup binary for the current platform and architecture.
    echo "Building GoBackup binary for ${GOBACKUP_PLATFORM}/${GOBACKUP_ARCHITECTURE} ..."
    if test $(id -u) -eq 0; then
      ${go_binary_path} build -o "${GOBACKUP_TEMP_PATH}/${GOBACKUP_BINARY}"
    else
      sudo ${go_binary_path} build -o "${GOBACKUP_TEMP_PATH}/${GOBACKUP_BINARY}"
    fi
  else
    # Download and extract GoBackup to the temporary directory
    echo "Downloading GoBackup v${GOBACKUP_VERSION} ..."
    curl -sSL "${GOBACKUP_RELEASE_URL}" | tar xzf -
  fi
  
  # Copy the GoBackup binary to the installation path.
  # (requires root privileges, so we need to use sudo if not running as root)
  echo "Installing GoBackup binary (this requires root privileges) ..."
  if test $(id -u) -eq 0; then
    cp -f "${GOBACKUP_TEMP_PATH}/${GOBACKUP_BINARY}" "${GOBACKUP_BINARY_PATH}"
  else
    sudo cp -f "${GOBACKUP_TEMP_PATH}/${GOBACKUP_BINARY}" "${GOBACKUP_BINARY_PATH}"
  fi

  # Ensure that the user specific GoBackup configuration directory exists.
  mkdir -p "${GOBACKUP_CONFIG_PATH}"

  echo "Successfully installed GoBackup v${GOBACKUP_VERSION}"
  return
}

# Ensures that the GoBackup configuration file exists
# at $PRINTER_DATA_PATH/config/gobackup.cfg,
# and is symlinked to $HOME/.gobackup/gobackup.yml.
function configure_gobackup() {
  local config_path="${PRINTER_DATA_PATH}/config/gobackup.cfg"
  local config_dir="$(dirname "${config_path}")"
  local config_file="$(basename "${config_path}")"
  local config_file_name="${config_file%.*}"
  local config_file_extension="${config_file##*.}"

  # Ensure that the configuration directory exists.
  mkdir -p "${config_dir}"

  # Check if the configuration file already exists.
  if test -e "${config_path}"; then
    echo "GoBackup configuration file already exists, skipping ..."
  else
    # Create a new configuration file.
    echo "Creating GoBackup configuration file ..."
    cat <<EOT >> "${config_path}"
#
# GoBackup configuration file.
#
# See the following URL for a configuration and usage reference:
# https://github.com/gobackup/gobackup
#

# Models defines the backup definition(s).
models:

  # An example backup definition,
  # that backs up the ~/printer_data folder.
  printer_data:

    # Run on a schedule.
    schedule:
      cron: "5 4 * * sun"     # Run at 04:05 every Sunday.

    # Archive backs up the defined path(s).
    archive:

      # Paths to include in the backup.
      includes:
        - ${PRINTER_DATA_PATH}

      # Paths to exclude from the backup.
      excludes:
        - ${PRINTER_DATA_PATH}/comms

    # Storages defines the location(s) where the backup should be stored.
    storages:

      # Local storage.
      local:
        type: local           # The storage type.
        path: ${HOME}/backups # The path where the backup should be stored.

      # S3 compatible storage.
      # s3:
      #   type: s3
      #   bucket: my_app_backup
      #   region: us-east-1
      #   path: backups
      #   access_key_id: \$S3_ACCESS_KEY_Id
      #   secret_access_key: \$S3_SECRET_ACCESS_KEY

    # Compression options.
    compress_with:
      type: tgz               # Compression type.
EOT
  fi

  # Check if the configuration file is already symlinked.
  if test -L "${GOBACKUP_CONFIG_PATH}/${config_file}"; then
    echo "GoBackup configuration file is already symlinked, skipping ..."
  else
    # Symlink the configuration file.
    echo "Symlinking GoBackup configuration file ..."
    ln -s "${config_path}" "${GOBACKUP_CONFIG_PATH}/${config_file}"
  fi

  echo "Successfully configured GoBackup"
}

# Function for installing or updating the custom systemd service for GoBackup.
function install_gobackup_service() {
  local source_path = "${GOBACKUP_TEMP_PATH}/${GOBACKUP_SERVICE_NAME}"
  local target_path = "/etc/systemd/system/${GOBACKUP_SERVICE_NAME}.service"

  local user = "$(id -un)"
  if test -z "${user}"; then
    echo "ERROR: Could not determine current user name" >&2
    exit 1
  fi

  local group = "$(id -gn)"
  if test -z "${group}"; then
    echo "ERROR: Could not determine current group name" >&2
    exit 1
  fi

  # Echo a systemd service file to the temporary directory.
  cat <<EOT >> "${source_path}"
# GOBACKUP_VERSION=${GOBACKUP_VERSION}
[Unit]
Description=GoBackup
After=moonraker.service

[Service]
Type=simple
User=${user}
Group=${group}
WorkingDirectory=${HOME}
ExecStart=${GOBACKUP_BINARY_PATH} start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOT

  # Check if this is a fresh install
  if test -e "${target_path}"; then
    echo "GoBackup systemd service already installed, checking for updates ..."

    # Check the GOBACKUP_VERSION of the service file to determine if we need to update it
    local service_version = "$(grep "^# GOBACKUP_VERSION=" "${target_path}" | awk -F= '{print $NF}')"
    if test "${service_version}" = "${GOBACKUP_VERSION}"; then
      echo "GoBackup systemd service already up-to-date"
      return
    else
      echo "Updating GoBackup systemd service from version ${service_version} to ${GOBACKUP_VERSION} ..."
    fi

  else
    echo "GoBackup systemd service is not installed, installing ..."
  fi

  # Copy the systemd service file to the installation path.
  # (requires root privileges, so we need to use sudo if not running as root)
  if test $(id -u) -eq 0; then
    cp -f "${source_path}" "${target_path}"
  else
    sudo cp -f "${source_path}" "${target_path}"
  fi

  # Reload systemd and its services.
  reload_systemd

  # Ensure that the GoBackup systemd service is always enabled.
  enable_systemd_service "${GOBACKUP_SERVICE_NAME}"
}

# Stop the GoBackup systemd service.
stop_systemd_service "${GOBACKUP_SERVICE_NAME}"

# Ensure that the GoBackup binary is installed and up-to-date.
install_gobackup

# Ensure that the GoBackup configuration is setup.
configure_gobackup

# Ensure that the custom systemd service is installed and up-to-date.
install_gobackup_service

# Start the GoBackup systemd service.
start_systemd_service "${GOBACKUP_SERVICE_NAME}"
