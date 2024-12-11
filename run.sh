#!/bin/sh
set -e

. /env.sh

if [ -z "$SCHEDULE" ]; then
    echo "[INFO] No SCHEDULE defined. Running backup once."
    /backup.sh
    exit 0
else
    echo "[INFO] SCHEDULE defined as '$SCHEDULE'. Setting up cron job."
    # Write out cron job
    echo "$SCHEDULE /backup.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/root
    echo "[INFO] Starting crond in foreground..."
    crond -f -l 2
fi
