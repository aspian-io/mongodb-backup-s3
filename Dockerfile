ARG MONGO_VERSION=6.0
FROM mongo:${MONGO_VERSION}
LABEL maintainer="Omid Rouhani <o.rohani@gmail.com>"

# Install AWS CLI
RUN apt-get update && apt-get install -y curl unzip cron && rm -rf /var/lib/apt/lists/*
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

COPY run.sh /usr/local/bin/run.sh
COPY backup.sh /backup.sh
COPY restore.sh /restore.sh
COPY env.sh /env.sh

RUN chmod +x /usr/local/bin/run.sh /backup.sh /restore.sh

ENV PATH="/usr/local/bin:$PATH"

ENTRYPOINT ["/usr/local/bin/run.sh"]
