#!/bin/sh
set -e

. /env.sh

read_secret() {
    VAR_NAME="$1"
    FILE_VAR_NAME="${VAR_NAME}_FILE"
    FILE_PATH="$(eval echo "\$$FILE_VAR_NAME")"
    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        VAL="$(cat "$FILE_PATH")"
        export $VAR_NAME="$VAL"
    fi
}

read_secret MONGODB_HOST
read_secret MONGODB_USER
read_secret MONGODB_PASS
read_secret MONGO_INITDB_ROOT_USERNAME
read_secret MONGO_INITDB_ROOT_PASSWORD
read_secret AWS_ACCESS_KEY_ID
read_secret AWS_SECRET_ACCESS_KEY
read_secret S3_ENDPOINT

if [ -z "$MONGODB_HOST" ]; then
    echo "[ERROR] MONGODB_HOST not set."
    exit 1
fi

if [ -z "$S3_BUCKET" ]; then
    echo "[ERROR] S3_BUCKET not set."
    exit 1
fi

AUTH_ARGS=""
if [ -n "$MONGODB_USER" ] && [ -n "$MONGODB_PASS" ]; then
    AUTH_ARGS="--username=$MONGODB_USER --password=$MONGODB_PASS"
elif [ -n "$MONGO_INITDB_ROOT_USERNAME" ] && [ -n "$MONGO_INITDB_ROOT_PASSWORD" ]; then
    AUTH_ARGS="--username=$MONGO_INITDB_ROOT_USERNAME --password=$MONGO_INITDB_ROOT_PASSWORD"
fi

TIMESTAMP="$1"

if [ -z "$TIMESTAMP" ]; then
    echo "[INFO] No timestamp provided, finding latest backup..."
    LATEST=$(aws s3 ls "s3://$S3_BUCKET/${S3_PREFIX:+$S3_PREFIX/}" \
        ${S3_REGION:+--region "$S3_REGION"} \
        ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"} \
        | grep mongodb-backup- | sort | tail -n 1 | awk '{print $4}')
    if [ -z "$LATEST" ]; then
        echo "[ERROR] No backups found."
        exit 1
    fi
    BACKUP_FILE="$LATEST"
else
    BACKUP_FILE="mongodb-backup-$TIMESTAMP"
fi

RESTORE_PATH="/tmp/restore.archive"
echo "[INFO] Downloading backup $BACKUP_FILE..."
aws s3 cp "s3://$S3_BUCKET/${S3_PREFIX:+$S3_PREFIX/}$BACKUP_FILE" "$RESTORE_PATH" \
    ${S3_REGION:+--region "$S3_REGION"} \
    ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"}

echo "[WARN] Restoring will DROP all existing data!"
mongorestore --host="$MONGODB_HOST" $AUTH_ARGS --drop --gzip --archive="$RESTORE_PATH"

rm -f "$RESTORE_PATH"
echo "[INFO] Restore completed successfully."
