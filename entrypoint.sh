#!/bin/bash

# Exit on command errors, unset variables, and failed piped commands.
set -euo pipefail

# Create the persisted OpenClaw state directory if it does not exist.
mkdir -p /data/.openclaw

# Restrict /data so only the app user can access it.
chmod 700 /data || true

# Seed persistent Homebrew storage the first time the container starts.
if [ ! -d /data/.linuxbrew ]; then
  cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
fi

# Replace the in-image Homebrew path with a symlink to persistent storage.
rm -rf /home/linuxbrew/.linuxbrew
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

# Start the app directly because the container already runs as the app user.
exec tini -- node src/server.js