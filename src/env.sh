#!/bin/sh

#######################################
# MongoDB Configuration
#######################################
: "${MONGODB_HOST:=}"
export MONGODB_HOST

: "${MONGODB_USER:=}"
export MONGODB_USER

: "${MONGODB_PASS:=}"
export MONGODB_PASS

: "${MONGO_INITDB_ROOT_USERNAME:=}"
export MONGO_INITDB_ROOT_USERNAME

: "${MONGO_INITDB_ROOT_PASSWORD:=}"
export MONGO_INITDB_ROOT_PASSWORD

#######################################
# AWS / S3 Configuration
#######################################
: "${AWS_ACCESS_KEY_ID:=}"
export AWS_ACCESS_KEY_ID

: "${AWS_SECRET_ACCESS_KEY:=}"
export AWS_SECRET_ACCESS_KEY

: "${S3_BUCKET:=}"
export S3_BUCKET

: "${S3_PREFIX:=}"
export S3_PREFIX

: "${S3_REGION:=}"
export S3_REGION

: "${S3_ENDPOINT:=}"
export S3_ENDPOINT

#######################################
# Backup & Schedule Configuration
#######################################
: "${BACKUP_KEEP_DAYS:=7}"
export BACKUP_KEEP_DAYS

: "${SCHEDULE:=}"
export SCHEDULE
