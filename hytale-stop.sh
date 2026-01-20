#!/bin/bash

# Define the Enter key character specifically
ENTER=$(printf \\r)

# 1. Send Warnings
# We inject the variable $ENTER so the server definitely processes the command
/usr/bin/screen -S hytale -p 0 -X stuff "notify Server stopping in 10 seconds...$ENTER"
/usr/bin/screen -S hytale -p 0 -X stuff "say Server stopping in 10 seconds...$ENTER"
/usr/bin/screen -S hytale -p 0 -X stuff "say Please disconnect and then try to reconnect shortly...$ENTER"
/usr/bin/screen -S hytale -p 0 -X stuff "notify Please disconnect and then try to reconnect shortly...$ENTER"

# 2. Wait for players to react
sleep 10

# 3. Graceful Shutdown
# Send 'stop' and press Enter
/usr/bin/screen -S hytale -p 0 -X stuff "stop$ENTER"

# 4. Wait loop with safety limit
# We wait up to 30 seconds for the server to save and close.
# If it takes longer, we exit so systemd can handle the cleanup.
MAX_RETRIES=85
COUNT=0

while /usr/bin/screen -list | grep -q "hytale"; do
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "Server failed to stop gracefully. Forcing exit."
        exit 1
    fi
    sleep 1
    COUNT=$((COUNT+1))
done
