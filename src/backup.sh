#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

echo "Creating backup of MongoDB database on host $MONGODB_HOST..."
timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
backup_file="/tmp/mongodb-backup-${timestamp}.archive"

echo "Running mongodump..."
mongodump --host "$MONGODB_HOST" \
          --username "$MONGODB_USER" \
          --password "$MONGODB_PASS" \
          --authenticationDatabase "$MONGODB_AUTH_DB" \
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

echo "Uploading backup to $s3_uri..."
aws $aws_args s3 cp "$backup_file" "$s3_uri"
rm "$backup_file"
echo "Backup uploaded successfully."

if [ -n "${BACKUP_KEEP_DAYS:-}" ]; then
  echo "Cleaning up old backups older than $BACKUP_KEEP_DAYS days..."
  sec=$((86400 * BACKUP_KEEP_DAYS))
  date_from_remove=$(date -d "@$(($(date +%s) - sec))" +%Y-%m-%d)
  backups_query="Contents[?LastModified<='${date_from_remove} 00:00:00'].{Key: Key}"

  aws $aws_args s3api list-objects \
    --bucket "${S3_BUCKET}" \
    --prefix "${S3_PREFIX}" \
    --query "${backups_query}" \
    --output text \
    | xargs -n1 -t -I 'KEY' aws $aws_args s3 rm s3://"${S3_BUCKET}"/'KEY'
  echo "Old backups cleaned up."
fi

echo "Backup process completed successfully."
