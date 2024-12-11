#!/bin/sh

#######################################
# MongoDB Configuration
#######################################
: "${MONGODB_HOST:=}"
if [ -n "${MONGODB_HOST_FILE:-}" ] && [ -f "${MONGODB_HOST_FILE}" ]; then
    MONGODB_HOST="$(cat "${MONGODB_HOST_FILE}")"
fi

: "${MONGODB_USER:=}"
if [ -n "${MONGODB_USER_FILE:-}" ] && [ -f "${MONGODB_USER_FILE}" ]; then
    MONGODB_USER="$(cat "${MONGODB_USER_FILE}")"
fi

: "${MONGODB_PASS:=}"
if [ -n "${MONGODB_PASS_FILE:-}" ] && [ -f "${MONGODB_PASS_FILE}" ]; then
    MONGODB_PASS="$(cat "${MONGODB_PASS_FILE}")"
fi

: "${MONGO_INITDB_ROOT_USERNAME:=}"
if [ -n "${MONGO_INITDB_ROOT_USERNAME_FILE:-}" ] && [ -f "${MONGO_INITDB_ROOT_USERNAME_FILE}" ]; then
    MONGO_INITDB_ROOT_USERNAME="$(cat "${MONGO_INITDB_ROOT_USERNAME_FILE}")"
fi

: "${MONGO_INITDB_ROOT_PASSWORD:=}"
if [ -n "${MONGO_INITDB_ROOT_PASSWORD_FILE:-}" ] && [ -f "${MONGO_INITDB_ROOT_PASSWORD_FILE}" ]; then
    MONGO_INITDB_ROOT_PASSWORD="$(cat "${MONGO_INITDB_ROOT_PASSWORD_FILE}")"
fi

#######################################
# AWS / S3 Configuration
#######################################
: "${AWS_ACCESS_KEY_ID:=}"
if [ -n "${AWS_ACCESS_KEY_ID_FILE:-}" ] && [ -f "${AWS_ACCESS_KEY_ID_FILE}" ]; then
    AWS_ACCESS_KEY_ID="$(cat "${AWS_ACCESS_KEY_ID_FILE}")"
fi

: "${AWS_SECRET_ACCESS_KEY:=}"
if [ -n "${AWS_SECRET_ACCESS_KEY_FILE:-}" ] && [ -f "${AWS_SECRET_ACCESS_KEY_FILE}" ]; then
    AWS_SECRET_ACCESS_KEY="$(cat "${AWS_SECRET_ACCESS_KEY_FILE}")"
fi

: "${S3_BUCKET:=}"
: "${S3_PREFIX:=}"
: "${S3_REGION:=}"
: "${S3_ENDPOINT:=}"
if [ -n "${S3_ENDPOINT_FILE:-}" ] && [ -f "${S3_ENDPOINT_FILE}" ]; then
    S3_ENDPOINT="$(cat "${S3_ENDPOINT_FILE}")"
fi

#######################################
# Backup & Schedule Configuration
#######################################
: "${BACKUP_KEEP_DAYS:=7}"
: "${SCHEDULE:=}"
