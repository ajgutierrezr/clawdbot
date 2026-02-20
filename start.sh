#!/usr/bin/env bash

echo "Starting virtual display..."
Xvfb :99 -screen 0 1280x1024x24 &
sleep 2

export DISPLAY=:99

echo "Starting Chromium..."
chromium \
  --remote-debugging-port=9222 \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --user-data-dir=/tmp/chrome-profile \
  > /dev/null 2>&1 &

sleep 3

echo "Starting OpenClaw gateway..."
openclaw gateway > /dev/null 2>&1 &

sleep 3

echo "Starting app..."
exec node src/server.js