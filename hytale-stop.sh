#!/bin/bash

# Define the Enter key character specifically
ENTER=$(printf \\r)

# 1. Send Warnings
# We inject the variable $ENTER so the server definitely processes the command
/usr/bin/screen -S hytale -p 0 -X stuff "notify Server stopping/restarting in 10 seconds...$ENTER"
/usr/bin/screen -S hytale -p 0 -X stuff "say Server stopping/restarting in 10 seconds...$ENTER"
sleep 1
/usr/bin/screen -S hytale -p 0 -X stuff "say Please disconnect and then try to reconnect in a few minutes...$ENTER"
/usr/bin/screen -S hytale -p 0 -X stuff "notify Please disconnect and then try to reconnect in a few minutes...$ENTER"

# 2. Wait for players to react
sleep 10

# 3. Graceful Shutdown
# Send 'stop' and press Enter
/usr/bin/screen -S hytale -p 0 -X eval 'stuff "stop \015"'

# 4. Wait loop with safety limit
# We wait up to 60 seconds for the server to save and close.
# If it takes longer, we exit so systemd can handle the cleanup.
MAX_RETRIES=60
COUNT=0

while /usr/bin/screen -list | grep -q "hytale"; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "Server failed to stop gracefully. Forcing exit."
        exit 1
    fi
    sleep 1
    COUNT=$((COUNT+1))
done