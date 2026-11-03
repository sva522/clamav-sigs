#!/bin/bash

mkdir /tmp/clamav-sigs && cd /tmp/clamav-sigs

# Install requires tools
sudo apt-get update
sudo apt-get install -y clamav xz zpaq jq curl wget

# Download official signatures
freshclam
ls -R /var/lib/clamav 

# Save official signatures
cp -R  /var/lib/clamav clamav-official-sigs

# Get unofficial signatures download scripts
REPO=extremeshok/clamav-unofficial-sigs
LAST_TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | jq -r .tag_name)
wget "https://github.com/${REPO}/archive/refs/tags/${LAST_TAG}.tar.gz"
tar xf "${LAST_TAG}.tar.gz"

# Download unofficial signatures
clamav-unofficial-sigs-*/clamav-unofficial-sigs.sh
ls -R /var/lib/clamav-unofficial-sigs
cp -R  /var/lib/clamav-unofficial-sigs clamav-unofficial-sigs

# Create release archive
tar cvf /tmp/clamav-sigs.tar .
xz -9 /tmp/clamav-sigs.tar
