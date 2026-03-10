#!/bin/bash
set -euo pipefail

# --- Runtime Configuration ---
MIN_RAM="8G"
MAX_RAM="8G"
SERVER_IP="0.0.0.0"
SERVER_PORT="5520"

# --- File Paths ---
JAR_FILE="Server/HytaleServer.jar"
ASSETS_PATH="Assets.zip"

# --- Backup Configuration ---
BACKUP_DIR="backups"
mkdir -p "$BACKUP_DIR"

# --- Server Arguments ---
ARGS=(--backup --backup-dir "$BACKUP_DIR" --backup-frequency 60 --log INFO)
JAVA_OPTS=(
  -XX:+UseG1GC
  -XX:+AlwaysPreTouch
  -XX:MaxDirectMemorySize=1G
  -XX:+ExitOnOutOfMemoryError
)

# --- Validation ---
if [[ ! -f "$JAR_FILE" ]]; then
  echo "Error: Could not find $JAR_FILE"
  echo "Run this script from the configured Hytale home directory."
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
