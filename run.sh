#!/bin/sh
set -e

. /env.sh

if [ -z "$SCHEDULE" ]; then
    echo "[INFO] No SCHEDULE defined. Running backup once."
    /backup.sh
    exit 0
else
    echo "[INFO] SCHEDULE defined as '$SCHEDULE'. Setting up cron job."

    # Create cron job file in /etc/cron.d/
    # Debian cron requires specifying a user (use 'root'), and no extra environment variables inside cron lines.
    echo "$SCHEDULE root /backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/mongodb-backup
    chmod 0644 /etc/cron.d/mongodb-backup

    # Ensure log file exists
    touch /var/log/cron.log

    echo "[INFO] Starting cron in foreground..."
    exec cron -f
fi
