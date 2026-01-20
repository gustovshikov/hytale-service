#!/bin/bash

# --- Configuration ---
SERVICE_NAME="hytale"
USER_NAME="hytale"
H_DIR="/home/hytale"
DOWNLOADER="$H_DIR/hytale-downloader-linux-amd64"
VERSION_FILE="$H_DIR/version_info.txt"
UPDATE_ZIP="$H_DIR/hytale_update.zip"

# Define the Enter key character specifically (Crucial for screen commands)
ENTER=$(printf \\r)

# Function to send commands to the screen session
send_msg() {
    su - $USER_NAME -c "screen -S hytale -p 0 -X stuff 'notify $1$ENTER'"
    sleep 1
    su - $USER_NAME -c "screen -S hytale -p 0 -X stuff 'say $1$ENTER'"
}

# --- 1. Check for Updates ---
echo "[Update-Check] Checking for latest version..."
REMOTE_VERSION=$(su - $USER_NAME -c "$DOWNLOADER -print-version")

if [ -f "$VERSION_FILE" ]; then
    LOCAL_VERSION=$(cat "$VERSION_FILE")
else
    LOCAL_VERSION="none"
fi

if [ "$REMOTE_VERSION" == "$LOCAL_VERSION" ]; then
    echo "[Update-Check] Server is up to date ($LOCAL_VERSION). Exiting."
    exit 0
fi

echo "[Update-Check] New version found! ($LOCAL_VERSION -> $REMOTE_VERSION)"

# --- 2. Download Update (Background) ---
echo "[Update-Script] Downloading update in background..."
su - $USER_NAME -c "$DOWNLOADER -download-path $UPDATE_ZIP"

if [ ! -f "$UPDATE_ZIP" ]; then
    echo "[Error] Download failed. Aborting update."
    exit 1
fi

# --- 3. Countdown Sequence ---
echo "[Update-Script] Starting countdown..."

send_msg "Update Ready! Server restarting in 5 minutes..."
sleep 180  # Wait 3 minutes (Remaining: 2m)

send_msg "Server restarting for update in 2 minutes!"
sleep 60   # Wait 1 minute (Remaining: 1m)

send_msg "Server restarting for update in 1 minute!"
sleep 30   # Wait 30 seconds (Remaining: 30s)

# --- The Adjustment ---
# We warn at 30 seconds, but only sleep 20.
# The remaining 10 seconds are handled by your hytale-stop.sh script.
send_msg "Server restarting for update in 30 seconds!"
sleep 20

# We do NOT send a "Restarting Now" message here.
# The stop script will handle the final "Stopping in 10s" message.

# --- 4. Stop and Apply ---
echo "[Update-Script] Stopping service..."
systemctl stop $SERVICE_NAME

echo "[Update-Script] Extracting files..."
su - $USER_NAME -c "unzip -o $UPDATE_ZIP -d $H_DIR"

rm "$UPDATE_ZIP"
echo "$REMOTE_VERSION" > "$VERSION_FILE"

echo "[Update-Script] Restarting service..."
systemctl start $SERVICE_NAME
echo "[Update-Script] Update Complete."
