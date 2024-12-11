#!/bin/sh

#######################################
# MONGODB CONFIGURATION
#######################################
: "${MONGODB_HOST:=}"           # Required, no default
: "${MONGODB_HOST_FILE:=}"      # File containing MONGODB_HOST
: "${MONGODB_USER:=}"           # Optional
: "${MONGODB_USER_FILE:=}"      # File containing MONGODB_USER
: "${MONGODB_PASS:=}"           # Optional
: "${MONGODB_PASS_FILE:=}"      # File containing MONGODB_PASS

#######################################
# AWS / S3 CONFIGURATION
#######################################
: "${AWS_ACCESS_KEY_ID:=}"           # Required
: "${AWS_ACCESS_KEY_ID_FILE:=}"      # File containing AWS_ACCESS_KEY_ID
: "${AWS_SECRET_ACCESS_KEY:=}"       # Required
: "${AWS_SECRET_ACCESS_KEY_FILE:=}"  # File containing AWS_SECRET_ACCESS_KEY
: "${S3_BUCKET:=}"                   # Required
: "${S3_PREFIX:=}"                   # Optional, default empty
: "${S3_REGION:=}"                   # Optional, default empty
: "${S3_ENDPOINT:=}"                 # Optional, default empty
: "${S3_ENDPOINT_FILE:=}"            # File containing S3_ENDPOINT

#######################################
# BACKUP RETENTION CONFIGURATION
#######################################
: "${BACKUP_KEEP_DAYS:=7}"  # Optional, default 7

#######################################
# Add any future environment variables here
#######################################
