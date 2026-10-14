#!/bin/bash source-this-script
# This script must be source as it is meant to set an environment variable.

# See https://oneuptime.com/blog/post/2026-03-18-configure-docker-socket-compatibility-podman/view
# See https://podman-desktop.io/docs/migrating-from-docker/using-the-docker_host-environment-variable

# Set DOCKER_HOST to the Docker compatability socket
export DOCKER_HOST=unix://$(podman info --format '{{.Host.RemoteSocket.Path}}')
echo "DOCKER_HOST=$DOCKER_HOST"
