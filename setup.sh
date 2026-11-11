#!/usr/bin/env bash
# Haspr APT Repository Setup Script
# https://github.com/haspr-dev/debian-repository

set -euo pipefail

REPO_URL="${HASPR_REPO_URL:-https://package.haspr.dev}"
KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="${KEYRING_DIR}/haspr-archive-keyring.gpg"
SOURCES_DIR="/etc/apt/sources.list.d"
SOURCES_FILE="${SOURCES_DIR}/haspr.sources"
LEGACY_LIST_FILE="${SOURCES_DIR}/haspr.list"

echo "=== Setting up Haspr Debian/Ubuntu Repository ==="

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root or with sudo." >&2
  exit 1
fi

# Check for apt-get
if ! command -v apt-get >/dev/null 2>&1; then
  echo "Error: apt-get not found. This script only supports Debian/Ubuntu-based distributions." >&2
  exit 1
fi

# Ensure curl and ca-certificates
if ! command -v curl >/dev/null 2>&1 || [ ! -f /etc/ssl/certs/ca-certificates.crt ]; then
  echo "Installing required dependencies (curl, ca-certificates, gnupg)..."
  apt-get update -qq
  apt-get install -y -qq curl ca-certificates gnupg >/dev/null
fi

# Create keyrings directory
mkdir -p -m 0755 "${KEYRING_DIR}"

# Download GPG keyring
echo "Downloading Haspr package signing key..."
if ! curl -fsSL "${REPO_URL}/haspr-archive-keyring.gpg" -o "${KEYRING_FILE}.tmp"; then
  # Fallback to ASCII armor key and dearmor
  curl -fsSL "${REPO_URL}/haspr.asc" | gpg --dearmor > "${KEYRING_FILE}.tmp"
fi
chmod 0644 "${KEYRING_FILE}.tmp"
mv "${KEYRING_FILE}.tmp" "${KEYRING_FILE}"

# Configure APT source repository
mkdir -p "${SOURCES_DIR}"

# Remove legacy list if present
rm -f "${LEGACY_LIST_FILE}"

echo "Configuring APT repository sources in ${SOURCES_FILE}..."
cat << EOF > "${SOURCES_FILE}"
Types: deb
URIs: ${REPO_URL}
Suites: stable
Components: main
Signed-By: ${KEYRING_FILE}
EOF
chmod 0644 "${SOURCES_FILE}"

echo "Updating APT package index..."
apt-get update -qq

echo ""
echo "=== Haspr APT Repository Successfully Configured! ==="
echo ""
echo "You can now install Haspr packages:"
echo "  sudo apt install haspr          # Haspr CLI tool & credential helper"
echo "  sudo apt install haspr-api-ce   # Haspr Community Edition API"
echo ""
