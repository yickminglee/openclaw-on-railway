#!/bin/bash
set -e

# Make persisted data root-owned because OpenClaw is being checked/loaded as root.
chown -R root:root /data

# Restrict /data so only root can access it.
chmod 700 /data

# Seed persistent Homebrew storage on first start.
if [ ! -d /data/.linuxbrew ]; then
  cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
fi

# Point the runtime Homebrew path at the persisted volume.
rm -rf /home/linuxbrew/.linuxbrew
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

# Start the app as root so plugin ownership matches what OpenClaw expects.
exec tini -- node src/server.js