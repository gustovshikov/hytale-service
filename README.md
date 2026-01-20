# Hytale-Service

This is how to configure the Hytale Dedicated Server to have a systemd service and have it auto update on a cron-job using teh CLI update tool from Hytale.

## Pre-setup

My server has a hytale user acount that runs the server and the game files are all in its home dir. You will need to manualy download the hytale cli update tool and configure the authentication to your account.

**Pre-Reqs**
1. `screen`
2. `hytale`

## Setup

Once the pre-setup is done follow these steps to have the scripts working. Modify the user and locations to your environment.

1. download the script files to the hytale home dir `/home/hytale/`.
   - `hytale-start.sh`
   - `hytale-stop.sh`
   - `auto-update.sh`

2. Get the hytale CLI and set it up in the home dir with the filename `hytale-downloader-linux-amd64`

3. Create systemd service file `hytale.service` in `/etc/systemd/system/`

4. Create crontab in root with the following setting will check for update every 8 hours at 0600, 1400, and 2200.

```bash
0 6,14,22 * * * /home/hytale/auto-update.sh >> /var/log/hytale-update.log 2>&1
```
5. you can test it by runnign teh cron command as root. `/home/hytale/auto-update.sh >> /var/log/hytale-update.log 2>&1`
