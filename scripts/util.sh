#!/usr/bin/env bash

GO_VERSION="1.20.3"

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

# Function for installing or updating Go.
function install_go() {
  ## TODO: Use PackageKit instead of apt-get directly!?

  # Check if Go is already installed.
  echo "Checking if Go is installed ..."
  local go="$(which go)"
  if test -e "${go}"; then
    # echo "Go already installed, checking for updates ..."

    # # Check if Go can be updated using apt-get.
    # if test $(id -u) -eq 0; then
    #   apt-get update --quiet
    #   apt-get upgrade --quiet -y golang
    # else
    #   sudo apt-get update --quiet
    #   sudo apt-get upgrade --quiet -y golang
    # fi

    # Check that Go version is at least 1.13.
    echo "Checking Go version ..."
    local go_version="$(go version | awk '{print $3}')"
    if test "$(printf '%s %s' "${go_version}" "1.13" | sort -V | head -n1)" = "1.13"; then
      echo "Go version ${go_version} is new enough, skipping installation ..."
      return
    else
      echo "Go version ${go_version} is not new enough, removing old version ..."
      if test $(id -u) -eq 0; then
        apt-get remove --quiet -y golang
      else
        sudo apt-get remove --quiet -y golang
      fi
    fi
  fi

  ## FIXME: Configure the version, platform and architecture with env vars
  ## FIXME: Configure the architecture so that eg. armv7l uses armv6l instead
  echo "Installing Go version ${GO_VERSION} ..."
  exec $SHELL -c "cd /usr/local && curl -sSL https://go.dev/dl/go${GO_VERSION}.linux-armv6l.tar.gz | tar xzf -"
  # curl -sSL https://go.dev/dl/go1.20.3.linux-armv6l.tar.gz | tar xzf -

  # Add Go to the PATH for the current shell session.
  export PATH=$PATH:/usr/local/go/bin

  # # Install Go using apt-get.
  # echo "Installing Go (this requires root privileges) ..."
  # if test $(id -u) -eq 0; then
  #   apt-get install --quiet -y golang
  # else
  #   sudo apt-get install --quiet -y golang
  # fi

  # Ensure that the correct versino of Go is installed.
  echo "Checking Go version ..."
  local go_version="$(go version | awk '{print $3}')"
  if test "${go_version}" != "go${GO_VERSION}"; then
    echo "ERROR: Go version ${go_version} is not the expected version ${GO_VERSION}" >&2
    exit 1
  fi

  echo "Successfully installed Go"
  return
}

# Function for reloading the systemd daemon and its services.
function reload_systemd() {
  echo "Reloading systemd daemon ..."
  if test $(id -u) -eq 0; then
    systemctl daemon-reload
  else
    sudo systemctl daemon-reload
  fi
}

# Function that checks if a systemd service file exists,
# based on the service name as the first argument.
function systemd_service_exists() {
  ## TODO: We might want to use systemctl instead of checking the file system directly, in case paths change in the future?
  if test -e "/etc/systemd/system/${1}.service"; then
    return 0
  else
    return 1
  fi
}

# Function for enabling a systemd service,
# based on the service name as the first argument.
function enable_systemd_service() {
  # Return early if the service does not exist.
  if ! systemd_service_exists "${1}"; then
    # return 1
    return
  fi

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
  # Return early if the service does not exist.
  if ! systemd_service_exists "${1}"; then
    # return 1
    return
  fi

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
  # Return early if the service does not exist.
  if ! systemd_service_exists "${1}"; then
    # return 1
    return
  fi

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
  # Return early if the service does not exist.
  if ! systemd_service_exists "${1}"; then
    # return 1
    return
  fi

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
  # Return early if the service does not exist.
  if ! systemd_service_exists "${1}"; then
    # return 1
    return
  fi

  echo "Restarting systemd service ${1} ..."
  if test $(id -u) -eq 0; then
    systemctl restart "${1}"
  else
    sudo systemctl restart "${1}"
  fi
}
