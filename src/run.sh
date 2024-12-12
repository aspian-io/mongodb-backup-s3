#!/bin/sh

. "$(dirname "$0")/env.sh"

if [ -z "$SCHEDULE" ]; then
    echo "[INFO] No SCHEDULE provided. Running backup once."
    /bin/bash /backup.sh
else
    echo "[INFO] SCHEDULE set to '$SCHEDULE'. Using go-cron for scheduling."
    echo "[INFO] Starting go-cron with schedule: $SCHEDULE"
    exec go-cron "$SCHEDULE" /bin/bash /backup.sh
fi
