#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

echo "Creating backup of MongoDB database on host $MONGODB_HOST..."
timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
backup_file="/tmp/mongodb-backup-${timestamp}.archive"

echo "Running mongodump..."
AUTH_DB=${MONGODB_AUTH_DB:-admin} # Default to 'admin' if not set
mongodump --host "$MONGODB_HOST" \
          --username "$MONGODB_USER" \
          --password "$MONGODB_PASS" \
          --authenticationDatabase "$AUTH_DB" \
          --archive="$backup_file" --gzip
echo "Backup created at $backup_file."

s3_uri="s3://${S3_BUCKET}/${S3_PREFIX}/mongodb-backup-${timestamp}.archive"

if [ -n "${PASSPHRASE:-}" ]; then
  echo "Encrypting backup..."
  encrypted_file="${backup_file}.gpg"
  gpg --symmetric --batch --passphrase "$PASSPHRASE" --output "$encrypted_file" "$backup_file"
  rm "$backup_file"
  backup_file="$encrypted_file"
  s3_uri="${s3_uri}.gpg"
fi

# Initialize AWS CLI arguments
aws_args=""
[ -n "${S3_REGION:-}" ] && aws_args+=" --region $S3_REGION"
[ -n "${S3_ENDPOINT:-}" ] && aws_args+=" --endpoint-url $S3_ENDPOINT"

echo "Uploading backup to $s3_uri..."
aws $aws_args s3 cp "$backup_file" "$s3_uri" || {
    echo "[ERROR] Failed to upload backup to S3."
    exit 1
}
rm "$backup_file"
echo "Backup uploaded successfully."

if [ -n "$BACKUP_KEEP_DAYS" ]; then
    sec=$((86400 * BACKUP_KEEP_DAYS))
    date_from_remove=$(date -d "@$(($(date +%s) - sec))" +%Y-%m-%d)
    backups_query="Contents[?LastModified<='${date_from_remove} 00:00:00'].{Key: Key}"

    echo "Cleaning up old backups older than $BACKUP_KEEP_DAYS days..."
    aws $aws_args s3api list-objects \
        --bucket "$S3_BUCKET" \
        --prefix "$S3_PREFIX" \
        --query "$backups_query" \
        --output text |
        while IFS= read -r key; do
            echo "Deleting old backup: $key"
            aws $aws_args s3 rm "s3://${S3_BUCKET}/${key}"
        done
    echo "Old backups cleaned up."
fi

echo "Backup process completed successfully."
