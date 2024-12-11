#!/bin/sh
set -e

. /env.sh

echo "[DEBUG][$(date)] Starting backup.sh..."
echo "[DEBUG] MONGODB_HOST=$MONGODB_HOST"
echo "[DEBUG] S3_BUCKET=$S3_BUCKET"
echo "[DEBUG] S3_PREFIX=$S3_PREFIX"
echo "[DEBUG] BACKUP_KEEP_DAYS=$BACKUP_KEEP_DAYS"
echo "[DEBUG] SCHEDULE=$SCHEDULE"

# Function to read secrets from *_FILE
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

# Load secrets
read_secret MONGODB_HOST
read_secret MONGODB_USER
read_secret MONGODB_PASS
read_secret MONGO_INITDB_ROOT_USERNAME
read_secret MONGO_INITDB_ROOT_PASSWORD
read_secret AWS_ACCESS_KEY_ID
read_secret AWS_SECRET_ACCESS_KEY
read_secret S3_ENDPOINT

# Validate required vars
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
    ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"}
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
                    ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"}
            fi
        fi
    done
else
    echo "[INFO][$(date)] No old backup cleanup required."
fi

echo "[INFO][$(date)] Backup process completed successfully."
