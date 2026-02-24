#!/usr/bin/env bash
set -e

echo "Starting virtual display..."
export DISPLAY=:99
Xvfb :99 -screen 0 1280x1024x24 &
sleep 2

echo "Starting Chromium..."
chromium \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-setuid-sandbox \
  --disable-gpu \
  --disable-software-rasterizer \
  --disable-features=UseDBus \
  --remote-debugging-port=18800 \
  --remote-debugging-address=127.0.0.1 \
  --user-data-dir=/tmp/chrome-profile \
  about:blank \
  > /dev/null 2>&1 &

sleep 4

echo "Starting OpenClaw gateway..."
export OPENCLAW_BROWSER_PROFILE=openclaw
openclaw gateway &

sleep 3

echo "Starting app..."
exec node src/server.js
