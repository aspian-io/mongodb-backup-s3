#!/bin/sh
set -e

: "${GOCRON_VERSION:=0.0.5}"
: "${TARGETARCH:=amd64}"

GOCRON_URL="https://github.com/ivoronin/go-cron/releases/download/v$GOCRON_VERSION/go-cron_${GOCRON_VERSION}_linux_${TARGETARCH}.tar.gz"
TEMP_FILE="/tmp/go-cron.tar.gz"

echo "[INFO] Downloading go-cron version $GOCRON_VERSION for architecture $TARGETARCH..."
curl -fsSL -o "$TEMP_FILE" "$GOCRON_URL" || {
    echo "[ERROR] Failed to download go-cron from $GOCRON_URL"
    exit 1
}

echo "[INFO] Extracting go-cron..."
tar -xzf "$TEMP_FILE" -C /tmp || {
    echo "[ERROR] Failed to extract go-cron from $TEMP_FILE"
    exit 1
}

echo "[INFO] Installing go-cron..."
mv /tmp/go-cron /usr/local/bin/go-cron
chmod +x /usr/local/bin/go-cron
rm -f "$TEMP_FILE"
echo "[INFO] go-cron installed successfully."
