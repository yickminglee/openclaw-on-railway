#!/bin/bash

# Exit immediately if a command fails, if an undefined variable is used, or if any command inside a pipe fails.
set -euo pipefail

# Create the OpenClaw data/plugin directory if it does not already exist.
mkdir -p /data/.openclaw

# Make sure /data and the OpenClaw directory are owned by the openclaw user.
chown -R openclaw:openclaw /data /data/.openclaw

# Restrict /data so only its owner can read, write, and enter it.
chmod 700 /data

# Check whether the persistent Homebrew directory already exists on the Railway volume.
if [ ! -d /data/.linuxbrew ]; then
  # Copy the baked-in Homebrew files into persistent storage the first time.
  cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew

  # Ensure the copied Homebrew files are owned by the openclaw user.
  chown -R openclaw:openclaw /data/.linuxbrew
fi

# Remove the original Homebrew directory path inside the container.
rm -rf /home/linuxbrew/.linuxbrew

# Replace it with a symlink to the persistent Railway volume.
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

# Start the app with tini, switch to the openclaw user,
# and replace the shell with the Node process.
exec tini -- gosu openclaw node src/server.js