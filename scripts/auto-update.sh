#!/bin/bash
set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SERVICE_NAME="__SERVICE_NAME__"
SCREEN_SESSION="__SCREEN_SESSION__"
USER_NAME="__USER_NAME__"
H_DIR="__HOME_DIR__"
DOWNLOADER="$H_DIR/hytale-downloader-linux-amd64"
VERSION_FILE="$H_DIR/version_info.txt"
UPDATE_ZIP="$H_DIR/hytale_update.zip"
LOCK_FILE="/tmp/${SERVICE_NAME}-auto-update.lock"
ENTER=$(printf '\r')

service_stopped_for_update=0
update_applied=0

cleanup() {
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo "[Error] Update failed (exit code: $exit_code)."
    if [[ $service_stopped_for_update -eq 1 ]]; then
      echo "[Recovery] Attempting to restart ${SERVICE_NAME}..."
      systemctl start "$SERVICE_NAME" || true
    fi
    echo "[Update-Script] Update aborted."
    return
  fi

  if [[ $update_applied -eq 1 ]]; then
    rm -f "$UPDATE_ZIP"
    echo "[Update-Script] Update complete."
  else
    echo "[Update-Script] No update applied."
  fi
}
trap cleanup EXIT

session_exists() {
  su - "$USER_NAME" -c "screen -list | grep -Fq '.${SCREEN_SESSION}'"
}

send_msg() {
  local message="$1"
  if ! session_exists; then
    return 0
  fi
  su - "$USER_NAME" -c "screen -S $SCREEN_SESSION -p 0 -X stuff '/notify ${message}${ENTER}'" || true
  sleep 1
  su - "$USER_NAME" -c "screen -S $SCREEN_SESSION -p 0 -X stuff '/say ${message}${ENTER}'" || true
}

if [[ ! -x "$DOWNLOADER" ]]; then
  echo "[Error] Downloader not found or not executable: $DOWNLOADER"
  exit 1
fi

if ! command -v flock >/dev/null 2>&1; then
  echo "[Error] flock is required but was not found."
  exit 1
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "[Update-Check] Another update process is already running. Exiting."
  exit 0
fi

echo "[Update-Check] Checking for latest version..."
REMOTE_VERSION="$(su - "$USER_NAME" -c "$DOWNLOADER -print-version" | tr -d '\r\n')"
if [[ -z "$REMOTE_VERSION" ]]; then
  echo "[Error] Remote version lookup returned empty output."
  exit 1
fi

if [[ -f "$VERSION_FILE" ]]; then
  LOCAL_VERSION="$(tr -d '\r\n' < "$VERSION_FILE")"
else
  LOCAL_VERSION="none"
fi

if [[ "$REMOTE_VERSION" == "$LOCAL_VERSION" ]]; then
  echo "[Update-Check] Server is up to date ($LOCAL_VERSION). Exiting."
  exit 0
fi

echo "[Update-Check] New version found! ($LOCAL_VERSION -> $REMOTE_VERSION)"

echo "[Update-Script] Downloading update..."
rm -f "$UPDATE_ZIP"
su - "$USER_NAME" -c "$DOWNLOADER -download-path $UPDATE_ZIP"
if [[ ! -s "$UPDATE_ZIP" ]]; then
  echo "[Error] Download failed or produced an empty archive."
  exit 1
fi

service_was_active=0
if systemctl is-active --quiet "$SERVICE_NAME"; then
  service_was_active=1
fi

if [[ $service_was_active -eq 1 ]]; then
  echo "[Update-Script] Starting countdown..."
  send_msg "Update ready! Server restarting in 5 minutes..."
  sleep 180
  send_msg "Server restarting for update in 2 minutes!"
  sleep 60
  send_msg "Server restarting for update in 1 minute!"
  sleep 30
  send_msg "Server restarting for update in 30 seconds!"
  sleep 20

  echo "[Update-Script] Stopping service..."
  systemctl stop "$SERVICE_NAME"
  service_stopped_for_update=1
else
  echo "[Update-Script] Service is not active. Skipping countdown and stop."
fi

echo "[Update-Script] Extracting files..."
su - "$USER_NAME" -c "unzip -o $UPDATE_ZIP -d $H_DIR"

if [[ $service_was_active -eq 1 ]]; then
  echo "[Update-Script] Restarting service..."
  systemctl start "$SERVICE_NAME"
  service_stopped_for_update=0
fi

echo "$REMOTE_VERSION" > "$VERSION_FILE"
update_applied=1
