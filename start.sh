#!/usr/bin/env bash
set -e

pkill -9 Xvfb || true
pkill -9 chromium || true
rm -f /tmp/.X*-lock
rm -rf /tmp/.X11-unix/*

echo "Starting virtual display..."
export DISPLAY=:99
# Use the binary directly to keep the display alive in the background
Xvfb :99 -screen 0 1280x1024x24 -ac +extension GLX +render -noreset &
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
  --remote-allow-origins=* \
  about:blank \
  > /dev/null 2>&1 &

timeout 15s bash -c 'until curl -s http://127.0.0.1:18800/json/version; do sleep 1; done'

echo "Starting OpenClaw gateway..."
export OPENCLAW_BROWSER_PROFILE=openclaw
openclaw gateway --profile openclaw &
echo "Waiting for OpenClaw Gateway (Port 18789)..."
timeout 30s bash -c 'until curl -s http://127.0.0.1:18789/health > /dev/null 2>&1; do sleep 1; done'
sleep 3

echo "Starting app..."
exec node src/server.js
