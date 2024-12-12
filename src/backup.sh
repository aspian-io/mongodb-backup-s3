#!/bin/bash
set -e
set -u
set -o pipefail

# Source the environment variables
. "$(dirname "$0")/env.sh"

echo "Creating backup of MongoDB database on host $MONGODB_HOST..."

# Set authentication arguments
AUTH_ARGS=""
if [ -n "$MONGODB_USER" ] && [ -n "$MONGODB_PASS" ]; then
  AUTH_ARGS="--username=$MONGODB_USER --password=$MONGODB_PASS"
elif [ -n "$MONGO_INITDB_ROOT_USERNAME" ] && [ -n "$MONGO_INITDB_ROOT_PASSWORD" ]; then
  AUTH_ARGS="--username=$MONGO_INITDB_ROOT_USERNAME --password=$MONGO_INITDB_ROOT_PASSWORD"
fi

# Generate backup
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")
BACKUP_NAME="mongodb-backup-${TIMESTAMP}.archive"
DUMP_PATH="/tmp/$BACKUP_NAME"

echo "Running mongodump..."
mongodump --host "$MONGODB_HOST" $AUTH_ARGS --archive="$DUMP_PATH" --gzip
echo "Backup created at $DUMP_PATH."

# Prepare S3 upload
S3_URI_BASE="s3://${S3_BUCKET}/${S3_PREFIX}/$BACKUP_NAME"

if [ -n "$PASSPHRASE" ]; then
  echo "Encrypting backup..."
  ENCRYPTED_DUMP_PATH="${DUMP_PATH}.gpg"
  gpg --symmetric --batch --passphrase "$PASSPHRASE" "$DUMP_PATH"
  rm "$DUMP_PATH"
  LOCAL_FILE="$ENCRYPTED_DUMP_PATH"
  S3_URI="${S3_URI_BASE}.gpg"
else
  LOCAL_FILE="$DUMP_PATH"
  S3_URI="$S3_URI_BASE"
fi

echo "Uploading backup to S3: $S3_BUCKET..."
aws s3 cp "$LOCAL_FILE" "$S3_URI" \
    ${S3_REGION:+--region "$S3_REGION"} \
    ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"} || {
  echo "[ERROR] Failed to upload backup to S3."
  exit 1
}
rm "$LOCAL_FILE"
echo "Backup uploaded successfully."

# Remove old backups if BACKUP_KEEP_DAYS is set
if [ -n "$BACKUP_KEEP_DAYS" ]; then
  SEC=$((86400 * BACKUP_KEEP_DAYS))
  DATE_FROM_REMOVE=$(date -d "@$(($(date +%s) - SEC))" +%Y-%m-%d)
  BACKUPS_QUERY="Contents[?LastModified<='${DATE_FROM_REMOVE} 00:00:00'].{Key: Key}"

  echo "Removing old backups from $S3_BUCKET..."
  aws s3api list-objects \
    --bucket "$S3_BUCKET" \
    --prefix "$S3_PREFIX" \
    --query "$BACKUPS_QUERY" \
    --output text \
    | xargs -n1 -t -I 'KEY' aws s3 rm s3://"$S3_BUCKET"/'KEY' || {
      echo "[WARN] Failed to remove some old backups."
    }
  echo "Old backup removal complete."
fi

echo "Backup process completed successfully."
