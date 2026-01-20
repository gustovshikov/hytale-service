#!/bin/bash

# --- Configuration ---
MIN_RAM="4G"
MAX_RAM="4G"
SERVER_IP="0.0.0.0"
SERVER_PORT="5520"

# --- File Paths ---
JAR_FILE="Server/HytaleServer.jar"
ASSETS_PATH="Assets.zip"
# AOT Cache removed due to version mismatch error
# AOT_CACHE="Server/HytaleServer.aot" 

# --- Backup Configuration ---
# Create the backup directory if it doesn't exist
BACKUP_DIR="backups"
mkdir -p "$BACKUP_DIR"

# --- Server Arguments ---
# Added --backup-dir
ARGS="--backup --backup-dir ${BACKUP_DIR} --backup-frequency 60 --log INFO"

# --- Validation ---
if [ ! -f "$JAR_FILE" ]; then
    echo "Error: Could not find $JAR_FILE"
    echo "Make sure you are running this script from /home/hytale/"
    exit 1
fi

# --- Launch Command ---
echo "Starting Hytale Server..."
echo "Identity: ${SERVER_IP}:${SERVER_PORT}"
echo "Backups: Enabled (Location: ./$BACKUP_DIR)"

java -Xms${MIN_RAM} -Xmx${MAX_RAM} \
    -jar "${JAR_FILE}" \
    --assets "${ASSETS_PATH}" \
    -b "${SERVER_IP}:${SERVER_PORT}" \
    $ARGS
