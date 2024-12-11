ARG MONGO_VERSION=8.0
FROM mongo:${MONGO_VERSION} AS base

ARG TARGETARCH
ARG GOCRON_VERSION=0.0.10

# Install dependencies
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && rm -rf awscliv2.zip aws

ADD src/install.sh install.sh
RUN sh install.sh && rm install.sh

ADD src/run.sh run.sh
ADD src/env.sh env.sh
ADD src/backup.sh backup.sh
ADD src/restore.sh restore.sh

CMD ["sh", "run.sh"]
