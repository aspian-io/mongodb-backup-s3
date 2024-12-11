#!/bin/sh
set -e

echo "[INFO] Starting MongoDB backup process..."
. /env.sh

# Function to read secrets from *_FILE if available
read_secret() {
    VAR_NAME="$1"
    FILE_VAR_NAME="${VAR_NAME}_FILE"
    FILE_PATH="$(eval echo "\$$FILE_VAR_NAME")"
    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        VAL="$(cat "$FILE_PATH")"
        export $VAR_NAME="$VAL"
        echo "[DEBUG] Loaded secret for $VAR_NAME from file $FILE_PATH"
    fi
}

# Read secrets
read_secret MONGODB_HOST
read_secret MONGODB_USER
read_secret MONGODB_PASS
read_secret AWS_ACCESS_KEY_ID
read_secret AWS_SECRET_ACCESS_KEY
read_secret S3_ENDPOINT

# Validate required variables
if [ -z "$MONGODB_HOST" ]; then
    echo "[ERROR] MONGODB_HOST is not set."
    exit 1
fi

if [ -z "$S3_BUCKET" ]; then
    echo "[ERROR] S3_BUCKET is not set."
    exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "[ERROR] AWS_ACCESS_KEY_ID is not set."
    exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "[ERROR] AWS_SECRET_ACCESS_KEY is not set."
    exit 1
fi

AUTH_ARGS=""
if [ -n "$MONGODB_USER" ] && [ -n "$MONGODB_PASS" ]; then
    AUTH_ARGS="--username=$MONGODB_USER --password=$MONGODB_PASS"
else
    echo "[WARN] MONGODB_USER or MONGODB_PASS not provided. Attempting connection without auth."
fi

[ -z "$S3_REGION" ] && echo "[WARN] S3_REGION not set. The AWS CLI may use a default region."
[ -z "$S3_ENDPOINT" ] && echo "[INFO] S3_ENDPOINT not set. Using the default AWS endpoint."
echo "[INFO] Using BACKUP_KEEP_DAYS=$BACKUP_KEEP_DAYS"
echo "[INFO] Using S3_PREFIX='${S3_PREFIX}' (if empty, backups go into the bucket root)"

TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_NAME="mongodb-backup-$TIMESTAMP"
DUMP_PATH="/tmp/$BACKUP_NAME"

echo "[INFO] Running mongodump to create backup..."
mongodump --host="$MONGODB_HOST" $AUTH_ARGS --archive="$DUMP_PATH" --gzip
echo "[INFO] mongodump completed successfully."

S3_URI="s3://$S3_BUCKET/${S3_PREFIX:+$S3_PREFIX/}$BACKUP_NAME"
echo "[INFO] Uploading backup to $S3_URI ..."
aws s3 cp "$DUMP_PATH" "$S3_URI" \
    ${S3_REGION:+--region "$S3_REGION"} \
    ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"}
echo "[INFO] Backup uploaded successfully."

rm -f "$DUMP_PATH"
echo "[INFO] Local backup file removed."

# Cleanup old backups
if [ -n "$BACKUP_KEEP_DAYS" ] && [ "$BACKUP_KEEP_DAYS" -gt 0 ]; then
    echo "[INFO] Cleaning up backups older than $BACKUP_KEEP_DAYS days..."
    OLD_DATE=$(date -d "-$BACKUP_KEEP_DAYS days" +%Y%m%d%H%M%S)
    aws s3 ls "s3://$S3_BUCKET/${S3_PREFIX:+$S3_PREFIX/}" \
        ${S3_REGION:+--region "$S3_REGION"} \
        ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"} | \
    while read -r line; do
        FILE=$(echo "$line" | awk '{print $4}')
        if echo "$FILE" | grep -q "^mongodb-backup-"; then
            FILE_TIMESTAMP=$(echo "$FILE" | sed 's/mongodb-backup-//')
            if [ "$FILE_TIMESTAMP" \< "$OLD_DATE" ]; then
                echo "[INFO] Deleting old backup: $FILE"
                aws s3 rm "s3://$S3_BUCKET/${S3_PREFIX:+$S3_PREFIX/}$FILE" \
                    ${S3_REGION:+--region "$S3_REGION"} \
                    ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"}
            fi
        fi
    done
else
    echo "[INFO] BACKUP_KEEP_DAYS not set or zero, skipping old backup cleanup."
fi

echo "[INFO] Backup and cleanup process completed successfully."
