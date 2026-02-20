#!/usr/bin/env bash

echo "Starting virtual display..."
Xvfb :99 -screen 0 1280x1024x24 &
sleep 2

export DISPLAY=:99

echo "Starting Xvfb..."
Xvfb :99 -screen 0 1280x800x24 &

echo "Starting Chromium..."
chromium \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --disable-software-rasterizer \
  --remote-debugging-port=9222 \
  --remote-debugging-address=127.0.0.1 \
  --user-data-dir=/tmp/chrome-profile \
  > /dev/null 2>&1 &

sleep 3

echo "Starting OpenClaw gateway..."
openclaw gateway > /dev/null 2>&1 &

sleep 3

echo "Starting app..."
exec node src/server.js