#!/usr/bin/env bash
# Haspr Package Repository Setup Script
# https://github.com/haspr-dev/package-repository

set -euo pipefail

REPO_URL="${HASPR_REPO_URL:-https://package.haspr.dev}"

echo "=== Setting up Haspr Package Repository ==="

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root or with sudo." >&2
  exit 1
fi

detect_pkg_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v zypper >/dev/null 2>&1; then
    echo "zypper"
  else
    echo "unknown"
  fi
}

PKG_MGR="$(detect_pkg_manager)"

case "$PKG_MGR" in
  apt)
    echo "Detected Debian/Ubuntu-based distribution (APT)."

    KEYRING_DIR="/etc/apt/keyrings"
    KEYRING_FILE="${KEYRING_DIR}/haspr-archive-keyring.gpg"
    SOURCES_DIR="/etc/apt/sources.list.d"
    SOURCES_FILE="${SOURCES_DIR}/haspr.sources"
    LEGACY_LIST_FILE="${SOURCES_DIR}/haspr.list"

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
      curl -fsSL "${REPO_URL}/haspr.asc" | gpg --dearmor > "${KEYRING_FILE}.tmp"
    fi
    chmod 0644 "${KEYRING_FILE}.tmp"
    mv "${KEYRING_FILE}.tmp" "${KEYRING_FILE}"

    # Configure APT source repository
    mkdir -p "${SOURCES_DIR}"
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
    echo "  sudo apt install haspr          # Haspr CLI & credential helpers"
    echo "  sudo apt install haspr-api-ce   # Haspr Community Edition API"
    echo ""
    ;;

  dnf|yum)
    echo "Detected RHEL/Fedora/CentOS/Rocky/AlmaLinux distribution (${PKG_MGR})."

    YUM_REPOS_DIR="/etc/yum.repos.d"
    REPO_FILE="${YUM_REPOS_DIR}/haspr.repo"

    mkdir -p "${YUM_REPOS_DIR}"

    echo "Configuring YUM/DNF repository in ${REPO_FILE}..."
    cat << EOF > "${REPO_FILE}"
[haspr]
name=Haspr Packages
baseurl=${REPO_URL}/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=${REPO_URL}/haspr.asc
EOF
    chmod 0644 "${REPO_FILE}"

    if command -v rpm >/dev/null 2>&1; then
      echo "Importing Haspr RPM GPG key..."
      rpm --import "${REPO_URL}/haspr.asc" || true
    fi

    echo "Updating ${PKG_MGR} package cache..."
    "${PKG_MGR}" check-update -q || true

    echo ""
    echo "=== Haspr RPM Repository Successfully Configured! ==="
    echo ""
    echo "You can now install Haspr packages:"
    echo "  sudo ${PKG_MGR} install haspr          # Haspr CLI & credential helpers"
    echo "  sudo ${PKG_MGR} install haspr-api-ce   # Haspr Community Edition API"
    echo ""
    ;;

  zypper)
    echo "Detected openSUSE/SLES distribution (zypper)."

    echo "Importing Haspr GPG key..."
    rpm --import "${REPO_URL}/haspr.asc" || true

    echo "Adding Haspr Zypper repository..."
    zypper ar -f -c "${REPO_URL}/rpm/" haspr || true
    zypper --gpg-auto-import-keys refresh haspr

    echo ""
    echo "=== Haspr Zypper Repository Successfully Configured! ==="
    echo ""
    echo "You can now install Haspr packages:"
    echo "  sudo zypper install haspr          # Haspr CLI & credential helpers"
    echo "  sudo zypper install haspr-api-ce   # Haspr Community Edition API"
    echo ""
    ;;

  *)
    echo "Error: Could not detect a supported package manager (apt-get, dnf, yum, zypper)." >&2
    echo "Please visit https://package.haspr.dev or download packages manually from https://github.com/haspr-dev/go-haspr-cli/releases" >&2
    exit 1
    ;;
esac
