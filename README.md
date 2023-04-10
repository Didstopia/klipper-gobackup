# GoBackup for Klipper (Moonraker)

This repository maintains the files necessary to install, update and configure [GoBackup](https://github.com/gobackup/gobackup) for Klipper (Moonraker).

***NOTE:*** *Work in progress!*

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
