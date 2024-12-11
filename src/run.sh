#!/bin/sh
set -eu

. /env.sh

# Run the backup immediately if no schedule is provided
if [ -z "$SCHEDULE" ]; then
    echo "[INFO] No SCHEDULE provided. Running backup once."
    /backup.sh
else
    echo "[INFO] SCHEDULE set to '$SCHEDULE'. Using go-cron for scheduling."
    exec go-cron "$SCHEDULE" /bin/sh /backup.sh
fi
