#!/bin/bash
set -euo pipefail

SCREEN_SESSION="__SCREEN_SESSION__"
ENTER=$(printf '\r')

session_exists() {
  /usr/bin/screen -list | grep -Fq ".${SCREEN_SESSION}"
}

send_cmd() {
  local command="$1"
  /usr/bin/screen -S "$SCREEN_SESSION" -p 0 -X stuff "${command}${ENTER}"
}

if ! session_exists; then
  echo "No ${SCREEN_SESSION} screen session found. Nothing to stop."
  exit 0
fi

send_cmd "/notify Server stopping/restarting in 10 seconds..."
send_cmd "/say Server stopping/restarting in 10 seconds..."
sleep 1
send_cmd "/say Please disconnect and then try to reconnect in a few minutes..."
send_cmd "/notify Please disconnect and then try to reconnect in a few minutes..."
sleep 10

send_cmd "/stop"

MAX_RETRIES=60
COUNT=0

while session_exists; do
  if [[ $COUNT -ge $MAX_RETRIES ]]; then
    echo "Server failed to stop gracefully within ${MAX_RETRIES}s."
    exit 1
  fi
  sleep 1
  COUNT=$((COUNT + 1))
done
