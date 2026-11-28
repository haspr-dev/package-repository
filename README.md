# Haspr Linux Package Repository

<p align="center">
  <img src="https://raw.githubusercontent.com/haspr-dev/.github/main/assets/haspr-logo.svg" alt="haspr logo" width="140" height="140" />
</p>

<p align="center">
  <strong>Official Debian, Ubuntu, Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux & openSUSE package repository for Haspr (haspr-api and go-haspr-cli).</strong>
</p>

---

## ⚡ Quick Start (Automated Detection)

Run the automated setup script. It automatically detects your distribution (Debian/Ubuntu, Fedora/RHEL, or openSUSE), configures repository sources, and imports our verified GPG signing key:

```bash
curl -fsSL https://package.haspr.dev/setup.sh | sudo bash
```

Then install the package you need:

### On Debian / Ubuntu:
```bash
sudo apt install haspr
```

### On Fedora / RHEL / CentOS / Rocky / AlmaLinux:
```bash
sudo dnf install haspr
# or: sudo yum install haspr
```

### On openSUSE / SLES:
```bash
sudo zypper install haspr
```

---

## 🛠️ Manual Installation

### A. Debian / Ubuntu (APT)

```bash
# 1. Install prerequisites
sudo apt-get update && sudo apt-get install -y curl ca-certificates

# 2. Add the Haspr GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://package.haspr.dev/haspr-archive-keyring.gpg | sudo tee /etc/apt/keyrings/haspr-archive-keyring.gpg > /dev/null

# 3. Add the APT source repository
cat << 'EOF' | sudo tee /etc/apt/sources.list.d/haspr.sources
Types: deb
URIs: https://package.haspr.dev
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/haspr-archive-keyring.gpg
EOF

# 4. Update and install
sudo apt-get update
sudo apt-get install haspr
```

### B. Fedora / RHEL / CentOS / Rocky / AlmaLinux (DNF / YUM)

```bash
# 1. Add Haspr repository definition
cat << 'EOF' | sudo tee /etc/yum.repos.d/haspr.repo
[haspr]
name=Haspr Packages
baseurl=https://package.haspr.dev/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://package.haspr.dev/haspr.asc
EOF

# 2. Import GPG signing key
sudo rpm --import https://package.haspr.dev/haspr.asc

# 3. Install packages
sudo dnf install haspr
```

### C. openSUSE / SLES (Zypper)

```bash
# 1. Import GPG signing key
sudo rpm --import https://package.haspr.dev/haspr.asc

# 2. Add repository and refresh
sudo zypper ar -f -c https://package.haspr.dev/rpm/ haspr
sudo zypper --gpg-auto-import-keys refresh haspr

# 3. Install packages
sudo zypper install haspr
```

---

## 📦 Hosted Packages

| Package | Formats | Architectures | Description |
| :--- | :--- | :--- | :--- |
| `haspr` | `.deb`, `.rpm` | `amd64` (`x86_64`), `arm64` (`aarch64`) | Haspr CLI, background authentication agent, and Git/Docker/AWS/K8s credential helpers. |
| `go-haspr-cli` | `.deb`, `.rpm` | `amd64` (`x86_64`), `arm64` (`aarch64`) | Compatibility package providing `haspr`. |
| `haspr-api-ce` | `.deb`, `.rpm` | `all` / `noarch` | Haspr Community Edition backend API server. |

---

## 🤖 Automated Repository Updates

This repository is continuously maintained and synchronized via GitHub Actions:
- Packages are retrieved automatically from releases in [`haspr-dev/go-haspr-cli`](https://github.com/haspr-dev/go-haspr-cli) and [`haspr-dev/haspr-api`](https://github.com/haspr-dev/haspr-api).
- APT indices (`Packages`, `Packages.gz`) and cryptographically signed release manifests (`Release`, `Release.gpg`, `InRelease`) are generated for Debian/Ubuntu suites (`stable`, `bookworm`, `trixie`, `noble`, `jammy`).
- RPM metadata (`repodata/repomd.xml`) and GPG detached signatures (`repodata/repomd.xml.asc`) are generated for Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux, and openSUSE.

---

## ⚖️ Trademark Notice

*Passbolt is a registered trademark of Passbolt SA. **Haspr** is an independent community project and is not affiliated with, endorsed by, or sponsored by Passbolt SA.*
