# Use Alpine base image
ARG MONGO_VERSION=8.0
FROM alpine:3.18 AS base

ARG TARGETARCH
ARG GOCRON_VERSION=0.0.5

# Install dependencies and MongoDB tools
RUN apk add --no-cache \
    bash \
    curl \
    unzip \
    jq \
    ca-certificates \
    openssl \
    shadow \
    && curl -fsSL "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-${MONGO_VERSION}.tgz" -o "mongodb.tgz" \
    && tar -zxvf mongodb.tgz --strip-components=1 -C /usr/local/bin/ \
    && rm -rf mongodb.tgz \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip && ./aws/install && rm -rf awscliv2.zip aws

# Create the /run/secrets directory for Docker secrets
RUN mkdir -p /run/secrets && chmod 0755 /run/secrets

# Add go-cron
COPY src/install.sh /install.sh
RUN chmod +x /install.sh && TARGETARCH=${TARGETARCH} GOCRON_VERSION=${GOCRON_VERSION} /install.sh

# Copy scripts
COPY src/env.sh /env.sh
COPY src/backup.sh /backup.sh
COPY src/restore.sh /restore.sh
COPY src/run.sh /run.sh

# Ensure scripts are executable
RUN chmod +x /env.sh /backup.sh /restore.sh /run.sh

# Add MongoDB binary to the PATH
ENV PATH="/usr/local/bin:$PATH"

# Set MONGO_VERSION as an environment variable for reference
ENV MONGO_VERSION=${MONGO_VERSION}

ENTRYPOINT ["/run.sh"]
