#!/bin/sh
set -e

echo "[DEBUG][$(date)] Starting backup.sh..."

. /env.sh

echo "[DEBUG][$(date)] Environment variables at backup start:"
echo "MONGODB_HOST=$MONGODB_HOST"
echo "MONGODB_USER=$MONGODB_USER"
echo "MONGO_INITDB_ROOT_USERNAME=$MONGO_INITDB_ROOT_USERNAME"
echo "S3_BUCKET=$S3_BUCKET"
echo "S3_PREFIX=$S3_PREFIX"
echo "S3_REGION=$S3_REGION"
echo "S3_ENDPOINT=$S3_ENDPOINT"
echo "BACKUP_KEEP_DAYS=$BACKUP_KEEP_DAYS"

# Function to read secrets from *_FILE if available
read_secret() {
    VAR_NAME="$1"
    FILE_VAR_NAME="${VAR_NAME}_FILE"
    FILE_PATH="$(eval echo "\$$FILE_VAR_NAME")"
    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        VAL="$(cat "$FILE_PATH")"
        export $VAR_NAME="$VAL"
        echo "[DEBUG][$(date)] Loaded secret for $VAR_NAME from file $FILE_PATH"
    fi
}

echo "[DEBUG][$(date)] Reading secrets..."
read_secret MONGODB_HOST
read_secret MONGODB_USER
read_secret MONGODB_PASS
read_secret MONGO_INITDB_ROOT_USERNAME
read_secret MONGO_INITDB_ROOT_PASSWORD
read_secret AWS_ACCESS_KEY_ID
read_secret AWS_SECRET_ACCESS_KEY
read_secret S3_ENDPOINT

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

AUTH_ARGS=""
if [ -n "$MONGODB_USER" ] && [ -n "$MONGODB_PASS" ]; then
    echo "[DEBUG][$(date)] Using MONGODB_USER and MONGODB_PASS for authentication."
    AUTH_ARGS="--username=$MONGODB_USER --password=$MONGODB_PASS"
elif [ -n "$MONGO_INITDB_ROOT_USERNAME" ] && [ -n "$MONGO_INITDB_ROOT_PASSWORD" ]; then
    echo "[DEBUG][$(date)] Using MONGO_INITDB_ROOT_USERNAME and MONGO_INITDB_ROOT_PASSWORD for authentication."
    AUTH_ARGS="--username=$MONGO_INITDB_ROOT_USERNAME --password=$MONGO_INITDB_ROOT_PASSWORD"
else
    echo "[WARN][$(date)] No authentication credentials found. Attempting no-auth backup."
fi

[ -z "$S3_REGION" ] && echo "[WARN][$(date)] S3_REGION not set. The AWS CLI may use a default region."
[ -z "$S3_ENDPOINT" ] && echo "[DEBUG][$(date)] S3_ENDPOINT not set. Using default AWS endpoint."
echo "[DEBUG][$(date)] BACKUP_KEEP_DAYS=$BACKUP_KEEP_DAYS"
echo "[DEBUG][$(date)] S3_PREFIX='$S3_PREFIX'"

TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_NAME="mongodb-backup-$TIMESTAMP"
DUMP_PATH="/tmp/$BACKUP_NAME"

echo "[INFO][$(date)] Running mongodump..."
mongodump --host="$MONGODB_HOST" $AUTH_ARGS --archive="$DUMP_PATH" --gzip
echo "[INFO][$(date)] mongodump completed successfully."

S3_URI="s3://$S3_BUCKET/${S3_PREFIX:+$S3_PREFIX/}$BACKUP_NAME"
echo "[INFO][$(date)] Uploading backup to $S3_URI..."
aws s3 cp "$DUMP_PATH" "$S3_URI" \
    ${S3_REGION:+--region "$S3_REGION"} \
    ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"} || { echo "[ERROR][$(date)] Failed to upload backup to S3."; exit 1; }
echo "[INFO][$(date)] Backup uploaded successfully."

rm -f "$DUMP_PATH"
echo "[INFO][$(date)] Local backup file removed."

if [ -n "$BACKUP_KEEP_DAYS" ] && [ "$BACKUP_KEEP_DAYS" -gt 0 ]; then
    echo "[INFO][$(date)] Cleaning up backups older than $BACKUP_KEEP_DAYS days..."
    OLD_DATE=$(date -d "-$BACKUP_KEEP_DAYS days" +%Y%m%d%H%M%S)
    aws s3 ls "s3://$S3_BUCKET/${S3_PREFIX:+$S3_PREFIX/}" \
        ${S3_REGION:+--region "$S3_REGION"} \
        ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"} | \
    while read -r line; do
        FILE=$(echo "$line" | awk '{print $4}')
        if echo "$FILE" | grep -q "^mongodb-backup-"; then
            FILE_TIMESTAMP=$(echo "$FILE" | sed 's/mongodb-backup-//')
            if [ "$FILE_TIMESTAMP" \< "$OLD_DATE" ]; then
                echo "[INFO][$(date)] Deleting old backup: $FILE"
                aws s3 rm "s3://$S3_BUCKET/${S3_PREFIX:+$S3_PREFIX/}$FILE" \
                    ${S3_REGION:+--region "$S3_REGION"} \
                    ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"} || echo "[WARN][$(date)] Failed to delete old backup $FILE."
            fi
        fi
    done
else
    echo "[INFO][$(date)] BACKUP_KEEP_DAYS not set or zero, skipping old backup cleanup."
fi

echo "[INFO][$(date)] Backup and cleanup process completed successfully."
