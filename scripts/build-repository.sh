#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== Building Debian APT Repository ==="

SUITES=("stable" "bookworm" "trixie" "noble" "jammy")
ARCHS=("amd64" "arm64" "all")

# Ensure required directories
mkdir -p pool/main
for suite in "${SUITES[@]}"; do
  for arch in "${ARCHS[@]}"; do
    mkdir -p "dists/${suite}/main/binary-${arch}"
  done
done

# Scan packages for each suite and architecture
for suite in "${SUITES[@]}"; do
  echo "--- Processing suite: ${suite} ---"
  
  for arch in "${ARCHS[@]}"; do
    TARGET_DIR="dists/${suite}/main/binary-${arch}"
    PACKAGES_FILE="${TARGET_DIR}/Packages"
    
    # Run dpkg-scanpackages for specific arch and all
    if command -v dpkg-scanpackages >/dev/null 2>&1; then
      dpkg-scanpackages --arch "${arch}" pool/main /dev/null > "${PACKAGES_FILE}" 2>/dev/null || true
    else
      echo "Warning: dpkg-scanpackages not found, generating empty Packages"
      touch "${PACKAGES_FILE}"
    fi

    # Compress Packages
    gzip -9c "${PACKAGES_FILE}" > "${PACKAGES_FILE}.gz"
    
    # Binary Release file
    cat << EOF > "${TARGET_DIR}/Release"
Component: main
Architecture: ${arch}
EOF
  done

  # Generate Suite Release file
  RELEASE_FILE="dists/${suite}/Release"
  DATE_NOW="$(date -Ru)"

  cat << EOF > "${RELEASE_FILE}"
Origin: Haspr
Label: Haspr
Suite: ${suite}
Codename: ${suite}
Architectures: amd64 arm64 all
Components: main
Description: Official Debian and Ubuntu packages for Haspr (haspr-api, go-haspr-cli)
Date: ${DATE_NOW}
EOF

  # Compute checksums for all files under dists/${suite}
  echo "MD5Sum:" >> "${RELEASE_FILE}"
  (cd "dists/${suite}" && find . -type f \( -name "Packages" -o -name "Packages.gz" -o -name "Release" \) ! -name "InRelease" ! -name "Release.gpg" -print0 | while IFS= read -r -d '' f; do
    clean_path="${f#./}"
    size="$(wc -c < "$f" | tr -d ' ')"
    hash="$(md5sum "$f" | awk '{print $1}')"
    printf " %s %8d %s\n" "$hash" "$size" "$clean_path"
  done) >> "${RELEASE_FILE}"

  echo "SHA256:" >> "${RELEASE_FILE}"
  (cd "dists/${suite}" && find . -type f \( -name "Packages" -o -name "Packages.gz" -o -name "Release" \) ! -name "InRelease" ! -name "Release.gpg" -print0 | while IFS= read -r -d '' f; do
    clean_path="${f#./}"
    size="$(wc -c < "$f" | tr -d ' ')"
    hash="$(sha256sum "$f" | awk '{print $1}')"
    printf " %s %8d %s\n" "$hash" "$size" "$clean_path"
  done) >> "${RELEASE_FILE}"

  # Sign Release file if GPG key is present
  if gpg --list-secret-keys packaging@haspr.dev >/dev/null 2>&1 || [ -n "${GPG_KEY_ID:-}" ]; then
    GPG_OPTS=()
    if [ -n "${GPG_KEY_ID:-}" ]; then
      GPG_OPTS+=(-u "${GPG_KEY_ID}")
    fi
    echo "Signing Release for ${suite}..."
    gpg "${GPG_OPTS[@]}" --armor --detach-sign -o "dists/${suite}/Release.gpg" --yes "${RELEASE_FILE}"
    gpg "${GPG_OPTS[@]}" --clear-sign -o "dists/${suite}/InRelease" --yes "${RELEASE_FILE}"
  else
    echo "Notice: No secret GPG key found. Skipping Release signing."
  fi
done

# --- Build RPM Repository ---
mkdir -p rpm
if ls rpm/*.rpm >/dev/null 2>&1; then
  echo "=== Building RPM Repository ==="
  if command -v createrepo_c >/dev/null 2>&1; then
    createrepo_c --update rpm/
  elif command -v createrepo >/dev/null 2>&1; then
    createrepo --update rpm/
  else
    echo "Warning: createrepo_c not found, skipping RPM index generation"
  fi

  if [ -f "rpm/repodata/repomd.xml" ]; then
    if gpg --list-secret-keys packaging@haspr.dev >/dev/null 2>&1 || [ -n "${GPG_KEY_ID:-}" ]; then
      GPG_OPTS=()
      if [ -n "${GPG_KEY_ID:-}" ]; then
        GPG_OPTS+=(-u "${GPG_KEY_ID}")
      fi
      echo "Signing RPM repomd.xml..."
      gpg "${GPG_OPTS[@]}" --armor --detach-sign -o "rpm/repodata/repomd.xml.asc" --yes "rpm/repodata/repomd.xml"
    else
      echo "Notice: No secret GPG key found. Skipping RPM repomd.xml signing."
    fi
  fi
fi

echo "=== Repository index generation complete ==="
