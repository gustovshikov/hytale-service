# Hytale Service Installer

This repo ships an installer that places runtime scripts in the right paths, installs a hardened `systemd` unit, and optionally configures root cron for auto-update.

## Repository layout

- `install.sh`: interactive installer (run as root)
- `scripts/hytale-start.sh`: server start script template
- `scripts/hytale-stop.sh`: graceful stop script template
- `scripts/auto-update.sh`: update script template
- `scripts/hytale.service`: hardened `systemd` unit template

## Prerequisites

- Linux host with `systemd`
- Hytale files already downloaded into your target home directory
- Hytale CLI downloader configured as `hytale-downloader-linux-amd64` in that home directory
- Commands: `screen`, `unzip`, `flock`, `systemctl`

`install.sh` checks these dependencies and installs missing ones automatically when a supported package manager is detected.

## Install

Run from repo root:

```bash
sudo ./install.sh
```

The installer will prompt for:

- Service name
- Runtime user/group
- Hytale home directory
- `screen` session name
- Cron schedule/log path for updates

It will then:

- Install scripts to `<home>/hytale-start.sh`, `<home>/hytale-stop.sh`, `<home>/auto-update.sh`
- Install `/etc/systemd/system/<service>.service`
- Reload and enable the service
- Optionally install root crontab entry for updates
- Optionally start/restart the service

## Manual update test

After install, test auto-update manually as root:

```bash
/home/hytale/auto-update.sh >> /var/log/hytale-update.log 2>&1
```
