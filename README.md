# GoBackup for Klipper (Moonraker)

This repository maintains the files necessary to install, update and configure [GoBackup](https://github.com/gobackup/gobackup) for Klipper (Moonraker).

***NOTE:*** *Work in progress!*

## Installation

Install GoBackup by checking out the repository and running the install script:

```bash
# Clone the repository
git clone https://github.com/Didstopia/klipper-gobackup.git ~/moonraker-gobackup

# Run the install script
~/moonraker-gobackup/scripts/install.sh
```

Optionally you can also setup automatic updates by adding the following `update_manager` entry to your `moonraker.conf` (or to the file where you configure Moonraker's update manager):

```yaml
# Update manager entry for GoBackup
[update_manager gobackup]
type: git_repo
channel: dev
path: ~/moonraker-gobackup
origin: https://github.com/Didstopia/klipper-gobackup.git
primary_branch: master
install_script: scripts/install.sh
managed_services: gobackup
```

Now you can restart Moonraker and GoBackup should be installed and configured, and kept up-to-date automatically.

## Configuration

**TODO**

## License

See [LICENSE](LICENSE).
