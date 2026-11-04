#!/bin/bash
set -euo pipefail

# Install required tools
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    ca-certificates clamav jq wget curl rsync dnsutils gnupg

# Install github cli
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg > /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
apt-get update -qq
apt-get install -y -qq --no-install-recommends gh

# Create build dir
work_dir="$PWD"
output_dir=/tmp/clamav-sigs
mkdir "$output_dir" && cd "$output_dir"

# Download official signatures
mkdir clamav-official-sigs && chown clamav:clamav clamav-official-sigs
freshclam --datadir="${output_dir}/clamav-official-sigs"

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

cd "$work_dir"

# Release tar
if [ -v GH_TOKEN ]; then
    gh release delete latest --cleanup-tag -y || true
    gh release create latest /tmp/clamav-sigs.tar \
    --repo "$GITHUB_REPOSITORY" \
    --title latest \
    --notes 'Last clamav signatures'
else
    echo 'No release was created.'
fi

