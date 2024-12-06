#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

VAULT_VERSION="1.18.2"
VAULT_BIN_PATH="/usr/local/bin/vault"
VAULT_CONFIG_PATH="/etc/vault"
VAULT_DATA_PATH="/var/lib/vault"
VAULT_SERVICE_FILE="/etc/systemd/system/vault.service"

install_dependencies() {
  echo "Installing required dependencies..."
  apt-get update -qq
  apt-get install -y -qq wget unzip
}

install_vault() {
  if [ -x "$VAULT_BIN_PATH" ]; then
    echo "Vault is already installed. Skipping installation."
    return
  fi

  echo "Installing HashiCorp Vault..."
  wget -q https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -O /tmp/vault.zip
  unzip -q /tmp/vault.zip -d /usr/local/bin
  chmod +x /usr/local/bin/vault
  rm /tmp/vault.zip

  echo "Vault installed at $(vault --version)"
}


configure_vault() {
  echo "Configuring Vault..."
  mkdir -p "$VAULT_CONFIG_PATH" "$VAULT_DATA_PATH"
  chmod 700 "$VAULT_DATA_PATH"

  cat > "$VAULT_CONFIG_PATH/vault.hcl" <<EOF
storage "file" {
  path = "$VAULT_DATA_PATH"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_cert_file = "/etc/vault/tls/cert.pem"
  tls_key_file  = "/etc/vault/tls/key.pem"
}

ui = true

api_addr = "https://medhelper.xyz:8200"
cluster_addr = "https://vault.medhelper.xyz:8201"
EOF

  chmod 600 "$VAULT_CONFIG_PATH/vault.hcl"
  mkdir -p /etc/vault/tls
  cp /etc/letsencrypt/live/vault.medhelper.xyz/fullchain.pem /etc/vault/tls/cert.pem
  cp /etc/letsencrypt/live/vault.medhelper.xyz/privkey.pem /etc/vault/tls/key.pem
  chmod 600 /etc/vault/tls/*
}

setup_vault_service() {
  if [ -f "$VAULT_SERVICE_FILE" ]; then
    echo "Vault service is already configured."
    return
  fi

  echo "Setting up Vault as a systemd service..."
  cat > "$VAULT_SERVICE_FILE" <<EOF
[Unit]
Description=HashiCorp Vault - A tool for managing secrets
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
User=root
Group=root
ExecStart=$VAULT_BIN_PATH server -config=$VAULT_CONFIG_PATH/vault.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

  chmod 644 "$VAULT_SERVICE_FILE"
  systemctl daemon-reload
  systemctl enable vault
  systemctl start vault
}

#initialize and unseal Vault
initialize_and_unseal_vault() {
  if [ -f "$VAULT_DATA_PATH/initialized" ]; then
    echo "Vault is already initialized and unsealed."
    return
  fi

  echo "Initializing Vault..."
  INIT_OUTPUT=$(vault operator init -key-shares=1 -key-threshold=1 -format=json)

  ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')
  UNSEAL_KEY=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[0]')

  echo "Unsealing Vault..."
  vault operator unseal "$UNSEAL_KEY"

  echo "Storing root token and unseal key securely..."
  echo "$ROOT_TOKEN" > "$VAULT_CONFIG_PATH/root_token"
  echo "$UNSEAL_KEY" > "$VAULT_CONFIG_PATH/unseal_key"

  chmod 600 "$VAULT_CONFIG_PATH/root_token" "$VAULT_CONFIG_PATH/unseal_key"
  touch "$VAULT_DATA_PATH/initialized"
}

install_dependencies
install_vault
configure_vault
setup_vault_service
initialize_and_unseal_vault

echo "Vault installation and setup complete."
