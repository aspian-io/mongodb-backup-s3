#!/bin/sh
set -eu

. /env.sh

# Configure AWS S3 Signature Version if required
if [ "$S3_S3V4" = "yes" ]; then
  aws configure set default.s3.signature_version s3v4
fi

# Run the backup immediately if no schedule is provided
if [ -z "$SCHEDULE" ]; then
  echo "[INFO] No SCHEDULE provided. Running backup once."
  /backup.sh
else
  echo "[INFO] SCHEDULE set to '$SCHEDULE'. Using go-cron for scheduling."
  exec go-cron "$SCHEDULE" /bin/sh /backup.sh
fi
