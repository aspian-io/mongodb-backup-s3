#!/bin/sh
set -e

. /env.sh

if [ -z "$SCHEDULE" ]; then
    echo "[INFO] No SCHEDULE provided. Running backup once."
    /backup.sh
    exit 0
else
    echo "[INFO] SCHEDULE set to '$SCHEDULE'. Using go-cron for scheduling."
    echo "[INFO] Starting go-cron with schedule: $SCHEDULE"
    exec go-cron -s "$SCHEDULE" -p 8080 -- /backup.sh
fi
