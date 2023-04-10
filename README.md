# GoBackup for Klipper (Moonraker)

This repository maintains the files necessary to install, update and configure [GoBackup](https://github.com/gobackup/gobackup) for Klipper (Moonraker).

***NOTE:*** *This is still a work in progress! Right now it should be functional, but changes are to be expected before this can be deemed stable for public consumption!*

## Features

- [x] Install script for easy installation of the `gobackup` binary, sample configuration file and systemd service
- [x] Automatic updates via Moonraker's update manager
- [ ] Install script cleanup, including more safeguards, error handling and better (more user friendly) logging
- [ ] Uninstall script cleanup, including more safeguards, error handling and better (more user friendly) logging
- [ ] Universal packages for all popular Klipper platforms and architectures (GoBackup only has binaries for x86 and arm64, however currently we build from source for all other architectures)
- [ ] Optional support for building from source for the current platform and architecture
- [ ] Configuration wizard for easy first time configuration of GoBackup
- [ ] Automatic setup for GoBackup's web interface if an existing nginx proxy is detected (eg. a new endpoint at `/gobackup`)
- [ ] Automatic setup of Moonraker integration (update manager entry, `moonraker.asvc` entry, starting/stopping/restarting Moonraker etc.)

## Installation

Start by checking out the repository to your home directory.

```bash
git clone https://github.com/Didstopia/klipper-gobackup.git ~/moonraker-gobackup
```

Now you can run the install script, which may take a while to complete, but should automatically setup everything for you.

```bash
~/moonraker-gobackup/scripts/install.sh
```

While optional, it is highly recommended that you also setup automatic updates, simply by adding the following `update_manager` entry to your `moonraker.conf` (or to the file where you configure Moonraker's update manager).

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

Ensure that you also add `gobackup` to the bottom of your `~/printer_data/moonraker.asvc` file, so that Moonraker can control the GoBackup service.

If you setup the automatic updates above, you may additionally need to restart Moonraker.

```bash
systemctl restart moonraker
```

GoBackup should now be installed and running, configured with an example configuration and kept up-to-date automatically.

## Configuration

You can find the configuration file at `~/printer_data/config/gobackup.cfg`.

If all went well, you should now be able to access the GoBackup web interface at `http://<your printer's IP address>:2703`, as well as verify its status by running `systemctl status gobackup`.

For more information on how to configure GoBackup, please refer to the [official GoBackup documentation](https://github.com/gobackup/gobackup).

## License

See [LICENSE](LICENSE).
