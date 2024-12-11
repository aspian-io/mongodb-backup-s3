#!/bin/sh

# Function to read secrets from *_FILE variables
read_env_file() {
    VAR_NAME="$1"
    FILE_VAR_NAME="${VAR_NAME}_FILE"
    FILE_PATH="$(eval echo "\$$FILE_VAR_NAME")"

    # Check if the *_FILE variable is set and the file exists
    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        export "$VAR_NAME"="$(cat "$FILE_PATH")"
        echo "[DEBUG][$(date)] Loaded secret for $VAR_NAME from $FILE_PATH"
    else
        # Fallback: If *_FILE is not set, ensure the main variable exists
        CURRENT_VALUE="$(eval echo "\$$VAR_NAME")"
        if [ -z "$CURRENT_VALUE" ]; then
            echo "[ERROR][$(date)] $VAR_NAME is not set and $FILE_VAR_NAME is not available."
            exit 1
        else
            echo "[DEBUG][$(date)] Environment variable $VAR_NAME is already set."
        fi
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
