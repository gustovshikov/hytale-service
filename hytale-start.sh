#!/bin/bash
set -euo pipefail

# --- Configuration ---
MIN_RAM="8G"
MAX_RAM="8G"
SERVER_IP="0.0.0.0"
SERVER_PORT="5520"

# --- File Paths ---
JAR_FILE="Server/HytaleServer.jar"
ASSETS_PATH="Assets.zip"
# AOT Cache removed due to Jave version mismatch error
# AOT_CACHE="Server/HytaleServer.aot" 

# --- Backup Configuration ---
# Create the backup directory if it doesn't exist
BACKUP_DIR="backups"
mkdir -p "$BACKUP_DIR"

# --- Server Arguments ---
# Added --backup-dir
ARGS=(--backup --backup-dir "$BACKUP_DIR" --backup-frequency 60 --log INFO)
# Added -XX:+AlwaysPreTouch to force OS to allocate memory at start (prevents lag spikes)
JAVA_OPTS=(
  -XX:+UseG1GC
  -XX:+AlwaysPreTouch
  -XX:MaxDirectMemorySize=1G
  -XX:+ExitOnOutOfMemoryError
)

# --- Validation ---
if [ ! -f "$JAR_FILE" ]; then
    echo "Error: Could not find $JAR_FILE"
    echo "Make sure you are running this script from /home/hytale/"
    exit 1
fi

if [[ ! -f "$ASSETS_PATH" ]]; then
  echo "Error: Could not find $ASSETS_PATH"
  exit 1
fi

# --- Launch Command ---
echo "Starting Hytale Server..."
echo "Identity: ${SERVER_IP}:${SERVER_PORT}"
echo "Backups: Enabled (Location: ./$BACKUP_DIR)"

exec java -Xms"$MIN_RAM" -Xmx"$MAX_RAM" "${JAVA_OPTS[@]}" \
  -jar "$JAR_FILE" \
  --assets "$ASSETS_PATH" \
  -b "${SERVER_IP}:${SERVER_PORT}" \
  "${ARGS[@]}"