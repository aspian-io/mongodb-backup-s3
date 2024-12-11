#!/bin/sh
set -e

. "$(dirname "$0")/env.sh"

echo "[DEBUG][$(date)] Starting backup.sh..."
echo "[DEBUG] MONGODB_HOST=$MONGODB_HOST"
echo "[DEBUG] S3_BUCKET=$S3_BUCKET"
echo "[DEBUG] S3_PREFIX=$S3_PREFIX"
echo "[DEBUG] BACKUP_KEEP_DAYS=$BACKUP_KEEP_DAYS"
echo "[DEBUG] SCHEDULE=$SCHEDULE"

# Validate required variables
if [ -z "$MONGODB_HOST" ]; then
    echo "[ERROR][$(date)] MONGODB_HOST is not set."
    exit 1
fi

if [ -z "$S3_BUCKET" ]; then
    echo "[ERROR][$(date)] S3_BUCKET is not set."
    exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "[ERROR][$(date)] AWS_ACCESS_KEY_ID is not set."
    exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "[ERROR][$(date)] AWS_SECRET_ACCESS_KEY is not set."
    exit 1
fi

# Configure authentication arguments
AUTH_ARGS=""
if [ -n "$MONGODB_USER" ] && [ -n "$MONGODB_PASS" ]; then
    AUTH_ARGS="--username=$MONGODB_USER --password=$MONGODB_PASS"
elif [ -n "$MONGO_INITDB_ROOT_USERNAME" ] && [ -n "$MONGO_INITDB_ROOT_PASSWORD" ]; then
    AUTH_ARGS="--username=$MONGO_INITDB_ROOT_USERNAME --password=$MONGO_INITDB_ROOT_PASSWORD"
fi

TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_NAME="mongodb-backup-$TIMESTAMP"
DUMP_PATH="/tmp/$BACKUP_NAME"

echo "[INFO][$(date)] Running mongodump..."
mongodump --host="$MONGODB_HOST" $AUTH_ARGS --archive="$DUMP_PATH" --gzip
echo "[INFO][$(date)] mongodump completed."

S3_URI="s3://$S3_BUCKET/${S3_PREFIX:+$S3_PREFIX/}$BACKUP_NAME"
echo "[INFO][$(date)] Uploading backup to $S3_URI ..."
aws s3 cp "$DUMP_PATH" "$S3_URI" \
    ${S3_REGION:+--region "$S3_REGION"} \
    ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"} || {
        echo "[ERROR][$(date)] Failed to upload backup to S3."
        exit 1
    }
echo "[INFO][$(date)] Backup uploaded successfully."

rm -f "$DUMP_PATH"
echo "[INFO][$(date)] Local backup removed."

if [ -n "$BACKUP_KEEP_DAYS" ] && [ "$BACKUP_KEEP_DAYS" -gt 0 ]; then
    echo "[INFO][$(date)] Cleaning old backups older than $BACKUP_KEEP_DAYS days..."
    OLD_DATE=$(date -d "-$BACKUP_KEEP_DAYS days" +%Y%m%d%H%M%S)
    aws s3 ls "s3://$S3_BUCKET/${S3_PREFIX:+$S3_PREFIX/}" \
        ${S3_REGION:+--region "$S3_REGION"} \
        ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"} | while read -r line; do
        FILE=$(echo "$line" | awk '{print $4}')
        if echo "$FILE" | grep -q "^mongodb-backup-"; then
            FILE_TIMESTAMP=$(echo "$FILE" | sed 's/mongodb-backup-//')
            if [ "$FILE_TIMESTAMP" \< "$OLD_DATE" ]; then
                echo "[INFO][$(date)] Deleting old backup: $FILE"
                aws s3 rm "s3://$S3_BUCKET/${S3_PREFIX:+$S3_PREFIX/}$FILE" \
                    ${S3_REGION:+--region "$S3_REGION"} \
                    ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"} || {
                        echo "[WARN][$(date)] Failed to delete old backup $FILE."
                    }
            fi
        fi
    done
else
    echo "[INFO][$(date)] No old backup cleanup required."
fi

echo "[INFO][$(date)] Backup process completed successfully."
