#!/bin/bash
set -euo pipefail

# Install required tools
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    ca-certificates git clamav jq wget curl rsync  \
    dnsutils gnupg >/dev/null

# Each build produce an archive which is released with 'latest' tag
echo 'Remove old latest tag:'
gh release delete latest --cleanup-tag -y || true # Remove release
git push --delete origin latest           || true # Remove git tag

# Create build dir
workdir=/tmp/clamav-sigs
mkdir "$workdir" && cd "$workdir"

# Download official signatures
mkdir clamav-official-sigs
chown clamav:clamav clamav-official-sigs
freshclam --datadir="${workdir}/clamav-official-sigs"

export GNUPGHOME=$(mktemp -d -p /dev/shm --suffix _gpg); chmod 0700 "$GNUPGHOME"

# Get unofficial signatures download scripts
repo=extremeshok/clamav-unofficial-sigs
last_tag=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name')
downloader_dir="unofficial-sigs-downloader"
wget -q "https://github.com/${repo}/archive/refs/tags/${last_tag}.tar.gz" -O tmp.tar.gz
tar xf tmp.tar.gz && rm tmp.tar.gz
mv clamav-unofficial-sigs-* "$downloader_dir"

# Perform minimal configuration
cat >> "${downloader_dir}/config/user.conf" << EOF
## MINIMUM MODIFICATION
clam_user="clamav"
clam_group="clamav"
user_configuration_complete="yes"
EOF

# Download unofficial signatures
"${downloader_dir}/clamav-unofficial-sigs.sh" -c "${downloader_dir}/config"
cp -R /var/lib/clamav-unofficial-sigs clamav-unofficial-sigs
rm -r "${downloader_dir}"

# Create release archive
chown -R clamav:clamav .
tar cf /tmp/clamav-sigs.tar .
tar tvf /tmp/clamav-sigs.tar

gh release create latest /tmp/clamav-sigs.tar --repo "$GH_REPO" --title latest
