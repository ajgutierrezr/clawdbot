# ---------- BUILD OPENCLAW ----------
FROM node:22-bookworm AS openclaw-build

RUN apt-get update && apt-get install -y \
    git curl ca-certificates python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

# bun required for build
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /openclaw

ARG OPENCLAW_GIT_REF=v2026.2.9
RUN git clone --depth 1 --branch "${OPENCLAW_GIT_REF}" https://github.com/openclaw/openclaw.git .

# relax version requirements
RUN set -eux; \
  find ./extensions -name 'package.json' -type f | while read -r f; do \
    sed -i -E 's/"openclaw"[[:space:]]*:[[:space:]]*">=[^"]+"/"openclaw": "*"/g' "$f"; \
    sed -i -E 's/"openclaw"[[:space:]]*:[[:space:]]*"workspace:[^"]+"/"openclaw": "*"/g' "$f"; \
  done

RUN pnpm install --no-frozen-lockfile
RUN pnpm build
RUN pnpm ui:install && pnpm ui:build

# ---------- RUNTIME IMAGE ----------
FROM node:22-bookworm

ENV NODE_ENV=production

# install chromium + virtual display + deps
RUN apt-get update && apt-get install -y \
    chromium \
    xvfb \
    dbus-x11 \
    x11-utils \
    fonts-liberation \
    libnss3 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libxshmfence1 \
    libxfixes3 \
    libxrender1 \
    libxi6 \
    libxtst6 \
    python3 python3-pip python3-venv \
    tini \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Python runtime + scraping libraries
RUN apt-get update && apt-get install -y python3 python3-pip \
 && ln -sf /usr/bin/python3 /usr/bin/python \
 && pip3 install --no-cache-dir --break-system-packages \
    requests beautifulsoup4 lxml

ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMIUM_PATH=/usr/bin/chromium
ENV DISPLAY=:99
ENV CHROME_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-setuid-sandbox --disable-gpu"

WORKDIR /app

# install node deps first (cache friendly)
COPY package.json ./
RUN npm install --omit=dev && npm cache clean --force

# copy openclaw build
COPY --from=openclaw-build /openclaw /openclaw

# create openclaw command
RUN printf '%s\n' '#!/usr/bin/env bash' 'exec node /openclaw/dist/entry.js "$@"' > /usr/local/bin/openclaw \
  && chmod +x /usr/local/bin/openclaw

# copy app source
COPY src ./src
COPY start.sh ./start.sh
RUN chmod +x start.sh

EXPOSE 8080

ENTRYPOINT ["tini", "--"]
CMD ["bash", "start.sh"]