#!/bin/sh
set -e

echo "[DEBUG][$(date)] run.sh started."
. /env.sh

echo "[DEBUG][$(date)] Checking SCHEDULE..."
if [ -z "$SCHEDULE" ]; then
    echo "[INFO][$(date)] No SCHEDULE defined. Running backup once."
    /backup.sh
    exit 0
else
    echo "[INFO][$(date)] SCHEDULE defined as '$SCHEDULE'. Setting up cron job."
    echo "[DEBUG][$(date)] Writing cron job to /etc/cron.d/mongodb-backup"
    echo "$SCHEDULE root . /env.sh; /backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/mongodb-backup
    chmod 0644 /etc/cron.d/mongodb-backup

    # Ensure log file exists
    touch /var/log/cron.log
    echo "[DEBUG][$(date)] Created /var/log/cron.log"

    # Start tailing log for visibility in docker logs
    echo "[DEBUG][$(date)] Tailing /var/log/cron.log in background..."
    tail -f /var/log/cron.log &
    TAIL_PID=$!

    echo "[INFO][$(date)] Starting cron in foreground with 'cron -f'..."
    exec cron -f
fi
