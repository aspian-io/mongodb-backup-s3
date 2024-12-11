#!/bin/sh

# Function to read secrets from *_FILE variables
read_env_file() {
    VAR_NAME="$1"
    FILE_VAR_NAME="${VAR_NAME}_FILE"

    if [ -n "${!FILE_VAR_NAME:-}" ]; then
        FILE_PATH="${!FILE_VAR_NAME}"
        if [ -f "$FILE_PATH" ]; then
            export "$VAR_NAME"="$(cat "$FILE_PATH")"
            echo "[DEBUG][$(date)] Loaded secret for $VAR_NAME from $FILE_PATH"
        else
            echo "[ERROR][$(date)] Secret file $FILE_PATH for $VAR_NAME does not exist."
            exit 1
        fi
    elif [ -n "${!VAR_NAME:-}" ]; then
        echo "[DEBUG][$(date)] Environment variable $VAR_NAME is already set."
    else
        echo "[ERROR][$(date)] $VAR_NAME is not set and $FILE_VAR_NAME is not available."
        exit 1
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
