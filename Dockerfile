FROM node:24-bookworm

# Fix the app user's UID so file ownership stays stable across redeploys.
ARG UID=1001

# Fix the app group's GID so group ownership also stays stable.
ARG GID=1001

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gosu \
    procps \
    python3 \
    build-essential \
    zip \
    tini \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g openclaw@latest clawhub@latest

# Keep compatibility with older OPENCLAW_ENTRY paths.
RUN mkdir -p /openclaw \
  && ln -sfn /usr/local/lib/node_modules/openclaw/dist /openclaw/dist

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm@10 && pnpm install --prod

COPY src ./src
COPY --chmod=755 entrypoint.sh ./entrypoint.sh

# Create a fixed group for the OpenClaw runtime user.
RUN groupadd -g ${GID} openclaw \
  \
  # Create a fixed non-root user for OpenClaw.
  && useradd -m -u ${UID} -g ${GID} -s /bin/bash openclaw \
  \
  # Create the persisted OpenClaw state directory explicitly.
  && mkdir -p /data/.openclaw /home/linuxbrew/.linuxbrew \
  \
  # Make app files, data, and Homebrew owned by the fixed runtime user.
  && chown -R ${UID}:${GID} /app /data /home/linuxbrew

# Switch build/runtime context to the fixed non-root user.
USER ${UID}:${GID}

# Install Homebrew as the same non-root user that will run the app.
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
ENV HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew"

ENV PORT=8080
ENV OPENCLAW_ENTRY=/usr/local/lib/node_modules/openclaw/dist/entry.js
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl -f http://localhost:8080/setup/healthz || exit 1

# Keep the final container running as the same non-root user.
ENTRYPOINT ["./entrypoint.sh"]