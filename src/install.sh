#!/bin/sh
set -e

: "${GOCRON_VERSION:=0.0.10}"

echo "[INFO] Installing go-cron version $GOCRON_VERSION for architecture $TARGETARCH..."
curl -L -o /tmp/go-cron.tar.gz "https://github.com/odise/go-cron/releases/download/$GOCRON_VERSION/go-cron-linux-$TARGETARCH.tar.gz"
tar xzf /tmp/go-cron.tar.gz -C /tmp
mv /tmp/go-cron /usr/local/bin/go-cron
chmod +x /usr/local/bin/go-cron
rm /tmp/go-cron.tar.gz
echo "[INFO] go-cron installed successfully."
