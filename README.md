# Haspr Debian / Ubuntu Repository

<p align="center">
  <img src="https://raw.githubusercontent.com/haspr-dev/.github/main/assets/haspr-logo.svg" alt="haspr logo" width="140" height="140" />
</p>

<p align="center">
  <strong>Official Debian & Ubuntu APT repository for Haspr packages (haspr-api and go-haspr-cli).</strong>
</p>

---

## ⚡ Quick Start

Run the automated setup script to add the GPG key and configure the APT sources:

```bash
curl -fsSL https://package.haspr.dev/setup.sh | sudo bash
```

Then install the package you need:

```bash
sudo apt install haspr
```

---

## 🛠️ Manual Installation

### 1. Install prerequisites
```bash
sudo apt-get update
sudo apt-get install -y curl ca-certificates
```

### 2. Add the Haspr GPG key
```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://package.haspr.dev/haspr-archive-keyring.gpg | sudo tee /etc/apt/keyrings/haspr-archive-keyring.gpg > /dev/null
```

### 3. Add the APT source repository
```bash
cat << 'EOF' | sudo tee /etc/apt/sources.list.d/haspr.sources
Types: deb
URIs: https://package.haspr.dev
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/haspr-archive-keyring.gpg
EOF
```

### 4. Install packages
```bash
sudo apt-get update
sudo apt-get install haspr
```

---

## 📦 Hosted Packages

| Package | Component | Architectures | Description |
| :--- | :--- | :--- | :--- |
| `haspr` | `main` | `amd64`, `arm64` | Haspr CLI, background authentication agent, and credential helpers. |
| `go-haspr-cli` | `main` | `amd64`, `arm64` | Legacy compatibility package for Haspr CLI. |
| `haspr-api-ce` | `main` | `all` | Haspr Community Edition backend API server package. |

---

## 🤖 Automated Repository Updates

This repository is automatically updated via GitHub Actions:
- Packages are retrieved automatically from releases in [`haspr-dev/go-haspr-cli`](https://github.com/haspr-dev/go-haspr-cli) and [`haspr-dev/haspr-api`](https://github.com/haspr-dev/haspr-api).
- Repository metadata, indices (`Packages`, `Packages.gz`), and cryptographic signatures (`Release`, `Release.gpg`, `InRelease`) are generated and deployed automatically.

---

## ⚖️ Trademark Notice

*Passbolt is a registered trademark of Passbolt SA. **Haspr** is an independent community project and is not affiliated with, endorsed by, or sponsored by Passbolt SA.*
