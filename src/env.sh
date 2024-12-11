#!/bin/sh

# Function to read secrets from *_FILE variables
read_env_file() {
    VAR_NAME="$1"
    FILE_VAR_NAME="${VAR_NAME}_FILE"
    FILE_PATH="$(eval echo "\$$FILE_VAR_NAME")"

    # If *_FILE is set and file exists, read its content
    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        export "$VAR_NAME"="$(cat "$FILE_PATH")"
    fi
}

#######################################
# MongoDB Configuration
#######################################
: "${MONGODB_HOST:=}"
read_env_file MONGODB_HOST

: "${MONGODB_USER:=}"
read_env_file MONGODB_USER

: "${MONGODB_PASS:=}"
read_env_file MONGODB_PASS

: "${MONGO_INITDB_ROOT_USERNAME:=}"
read_env_file MONGO_INITDB_ROOT_USERNAME

: "${MONGO_INITDB_ROOT_PASSWORD:=}"
read_env_file MONGO_INITDB_ROOT_PASSWORD

#######################################
# AWS / S3 Configuration
#######################################
: "${AWS_ACCESS_KEY_ID:=}"
read_env_file AWS_ACCESS_KEY_ID

: "${AWS_SECRET_ACCESS_KEY:=}"
read_env_file AWS_SECRET_ACCESS_KEY

: "${S3_BUCKET:=}"
: "${S3_PREFIX:=}"
: "${S3_REGION:=}"
: "${S3_ENDPOINT:=}"
read_env_file S3_ENDPOINT

#######################################
# Backup & Schedule Configuration
#######################################
: "${BACKUP_KEEP_DAYS:=7}"
: "${SCHEDULE:=}"
