#!/bin/sh

#######################################
# MONGODB CONFIGURATION
#######################################
: "${MONGODB_HOST:=}"
: "${MONGODB_HOST_FILE:=}"
: "${MONGODB_USER:=}"
: "${MONGODB_USER_FILE:=}"
: "${MONGODB_PASS:=}"
: "${MONGODB_PASS_FILE:=}"

#######################################
# AWS / S3 CONFIGURATION
#######################################
: "${AWS_ACCESS_KEY_ID:=}"
: "${AWS_ACCESS_KEY_ID_FILE:=}"
: "${AWS_SECRET_ACCESS_KEY:=}"
: "${AWS_SECRET_ACCESS_KEY_FILE:=}"
: "${S3_BUCKET:=}"
: "${S3_PREFIX:=}"   # If set, backups will be placed under this prefix (folder) in the S3 bucket
: "${S3_REGION:=}"
: "${S3_ENDPOINT:=}"
: "${S3_ENDPOINT_FILE:=}"

#######################################
# BACKUP RETENTION
#######################################
: "${BACKUP_KEEP_DAYS:=7}"

#######################################
# SCHEDULE CONFIGURATION (CRON)
#######################################
: "${SCHEDULE:=}"
