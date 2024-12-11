ARG MONGO_VERSION=8.0
FROM mongo:${MONGO_VERSION} AS base

ARG TARGETARCH
ARG GOCRON_VERSION=0.0.10

# Install dependencies
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && rm -rf awscliv2.zip aws

COPY src/install.sh /install.sh
RUN chmod +x /install.sh && /install.sh

COPY src/env.sh /env.sh
COPY src/backup.sh /backup.sh
COPY src/restore.sh /restore.sh
COPY src/run.sh /run.sh

RUN chmod +x /backup.sh /restore.sh /run.sh

ENV PATH="/usr/local/bin:$PATH"

ENTRYPOINT ["/run.sh"]
