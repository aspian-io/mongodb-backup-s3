#!/bin/sh

#######################################
# MongoDB Configuration
#######################################
: "${MONGODB_HOST:=}"
if [ -n "${MONGODB_HOST_FILE:-}" ] && [ -f "${MONGODB_HOST_FILE}" ]; then
    MONGODB_HOST="$(cat "${MONGODB_HOST_FILE}")"
fi
export MONGODB_HOST

: "${MONGODB_USER:=}"
if [ -n "${MONGODB_USER_FILE:-}" ] && [ -f "${MONGODB_USER_FILE}" ]; then
    MONGODB_USER="$(cat "${MONGODB_USER_FILE}")"
fi
export MONGODB_USER

: "${MONGODB_PASS:=}"
if [ -n "${MONGODB_PASS_FILE:-}" ] && [ -f "${MONGODB_PASS_FILE}" ]; then
    MONGODB_PASS="$(cat "${MONGODB_PASS_FILE}")"
fi
export MONGODB_PASS

: "${MONGO_INITDB_ROOT_USERNAME:=}"
if [ -n "${MONGO_INITDB_ROOT_USERNAME_FILE:-}" ] && [ -f "${MONGO_INITDB_ROOT_USERNAME_FILE}" ]; then
    MONGO_INITDB_ROOT_USERNAME="$(cat "${MONGO_INITDB_ROOT_USERNAME_FILE}")"
fi
export MONGO_INITDB_ROOT_USERNAME

: "${MONGO_INITDB_ROOT_PASSWORD:=}"
if [ -n "${MONGO_INITDB_ROOT_PASSWORD_FILE:-}" ] && [ -f "${MONGO_INITDB_ROOT_PASSWORD_FILE}" ]; then
    MONGO_INITDB_ROOT_PASSWORD="$(cat "${MONGO_INITDB_ROOT_PASSWORD_FILE}")"
fi
export MONGO_INITDB_ROOT_PASSWORD

#######################################
# AWS / S3 Configuration
#######################################
: "${AWS_ACCESS_KEY_ID:=}"
if [ -n "${AWS_ACCESS_KEY_ID_FILE:-}" ] && [ -f "${AWS_ACCESS_KEY_ID_FILE}" ]; then
    AWS_ACCESS_KEY_ID="$(cat "${AWS_ACCESS_KEY_ID_FILE}")"
fi
export AWS_ACCESS_KEY_ID

: "${AWS_SECRET_ACCESS_KEY:=}"
if [ -n "${AWS_SECRET_ACCESS_KEY_FILE:-}" ] && [ -f "${AWS_SECRET_ACCESS_KEY_FILE}" ]; then
    AWS_SECRET_ACCESS_KEY="$(cat "${AWS_SECRET_ACCESS_KEY_FILE}")"
fi
export AWS_SECRET_ACCESS_KEY

: "${S3_BUCKET:=}"
export S3_BUCKET

: "${S3_PREFIX:=}"
export S3_PREFIX

: "${S3_REGION:=}"
export S3_REGION

: "${S3_ENDPOINT:=}"
if [ -n "${S3_ENDPOINT_FILE:-}" ] && [ -f "${S3_ENDPOINT_FILE}" ]; then
    S3_ENDPOINT="$(cat "${S3_ENDPOINT_FILE}")"
fi
export S3_ENDPOINT

#######################################
# Backup & Schedule Configuration
#######################################
: "${BACKUP_KEEP_DAYS:=7}"
export BACKUP_KEEP_DAYS

: "${SCHEDULE:=}"
export SCHEDULE
