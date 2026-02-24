#!/usr/bin/env bash
set -e

pkill -9 Xvfb || true
pkill -9 chromium || true
rm -f /tmp/.X99-lock
rm -f /tmp/.X11-unix/X99

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

timeout 15s bash -c 'until curl -s http://127.0.0.1:18800/json/version; do sleep 1; done'

echo "Starting OpenClaw gateway..."
export OPENCLAW_BROWSER_PROFILE=openclaw
openclaw gateway &

sleep 3

echo "Starting app..."
exec node src/server.js
