ARG MONGO_VERSION=8.0
FROM mongo:${MONGO_VERSION}
LABEL maintainer="Omid Rouhani <o.rohani@gmail.com>"

# Install AWS CLI and cron
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/* \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip aws \
    && apt-get clean

# Install BusyBox (includes crond) if not present
RUN apt-get update && apt-get install -y busybox && rm -rf /var/lib/apt/lists/*

# Create the crontab directory expected by busybox crond
RUN mkdir -p /etc/crontabs && touch /etc/crontabs/root

COPY run.sh /usr/local/bin/run.sh
COPY backup.sh /backup.sh
COPY restore.sh /restore.sh
COPY env.sh /env.sh

RUN chmod +x /usr/local/bin/run.sh /backup.sh /restore.sh

ENV PATH="/usr/local/bin:$PATH"

ENTRYPOINT ["/usr/local/bin/run.sh"]
