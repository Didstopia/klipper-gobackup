#!/usr/bin/env bash

#
# Installation script for GoBackup for Klipper.
#
# Based loosely on the following files/projects:
# - https://github.com/gobackup/gobackup/blob/main/install
# - https://github.com/eliteSchwein/mooncord/blob/master/scripts/install.sh
#

# Enable error handling
set -eo pipefail

# Enable script debugging
set -x

# Define global variables
GOBACKUP_REPOSITORY="gobackup/gobackup"
GOBACKUP_VERSION="2.0.1"
GOBACKUP_BINARY="gobackup"
GOBACKUP_PLATFORM="$(uname | tr "[A-Z]" "[a-z]")"
GOBACKUP_ARCHITECTURE="$(uname -m | sed 's/x86_64/amd64/')"
GOBACKUP_RELEASE_FILENAME="gobackup-${platform}-${arch}.tar.gz"
GOBACKUP_RELEASE_URL="https://github.com/${GOBACKUP_REPOSITORY}/releases/download/${GOBACKUP_VERSION}/${GOBACKUP_RELEASE_FILENAME}"
GOBACKUP_INSTALL_PATH="/usr/local/bin"
GOBACKUP_BINARY_PATH="${GOBACKUP_INSTALL_PATH}/${GOBACKUP_BINARY}"
GOBACKUP_TEMP_PATH="$(mktemp -d)"

# Setup a signal trap to always clean up when terminating
trap "cleanup" EXIT

# Function for cleaning up when terminating the script.
function cleanup() {
  # Remove the temporary directory
  rm -r ${GOBACKUP_TEMP_PATH}
}

# Function for installing or updating the GoBackup binary itself.
function install_gobackup() {
  # Check if GoBackup is already installed
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
  
  # Switch to the temporary directory
  cd "${GOBACKUP_TEMP_PATH}"
  
  # Download and extract GoBackup to the temporary directory
  curl -sSL "${GOBACKUP_RELEASE_URL}" | tar xzf -
  
  echo "Successfully installed GoBackup v${GOBACKUP_VERSION}"
  return
}

# Function for installing or updating the custom systemd service for GoBackup.
function install_gobackup_service() {
  
}
