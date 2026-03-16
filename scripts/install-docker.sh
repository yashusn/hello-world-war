#!/bin/bash
set -e

echo "Updating packages..."
apt-get update -y

echo "Installing dependencies..."
apt-get install -y ca-certificates curl gnupg lsb-release

echo "Adding Docker GPG key..."
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "Adding Docker repository..."
echo \
"deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" \
> /etc/apt/sources.list.d/docker.list

echo "Installing Docker..."
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

echo "Starting Docker..."
service docker start

echo "Docker version:"
docker --version
