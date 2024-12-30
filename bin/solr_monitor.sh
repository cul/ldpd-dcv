#!/bin/bash

MONITOR_FILE="./tmp/shutdown_tunnel_signal"
PID_FILE="./tmp/ssh_tunnel.pid"

if [ -f "$PID_FILE" ]; then
    TUNNEL_PID=$(cat "$PID_FILE")
    echo "Solr monitor read PID from $PID_FILE: $TUNNEL_PID"
else
    echo "Solr monitor PID file $PID_FILE not found. Monitor exiting."
    exit 1
fi

while true; do
    if [ -f "$MONITOR_FILE" ]; then
        echo "Signal file detected. Killing tunnel process with PID $TUNNEL_PID..."
        
        # Kill the tunnel process
        if kill "$TUNNEL_PID"; then
            echo "Tunnel process killed successfully."
        else
            echo "Failed to kill tunnel process or process not found."
        fi
        
        rm -f "$MONITOR_FILE"
        rm -f "$PID_FILE"

        # Exit the monitoring script
        echo "Exiting monitoring script."
        exit 0
    fi
    sleep 1
done
