#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

VAULT_VERSION="1.18.2"
VAULT_BIN_PATH="/usr/local/bin/vault"
VAULT_BASE_PATH="/etc/vault"
VAULT_DATA_BASE_PATH="/var/lib/vault"
VAULT_SERVICE_BASE_FILE="/etc/systemd/system/vault"
INSTANCE_NAME=${1:-"default"}
PORT=${2:-8200}
CLUSTER_PORT=${3:-8201}
DOMAIN=${4:-"localhost"}


install_dependencies() {
  echo "Installing required dependencies..."
  apt-get update -qq
  apt-get install -y -qq wget unzip jq
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
  local config_path="$VAULT_BASE_PATH/$INSTANCE_NAME"
  local data_path="$VAULT_DATA_BASE_PATH/$INSTANCE_NAME"

  echo "Configuring Vault instance '$INSTANCE_NAME'..."
  mkdir -p "$config_path" "$data_path"
  chmod 700 "$data_path"

  cat > "$config_path/vault.hcl" <<EOF
storage "file" {
  path = "$data_path"
}

listener "tcp" {
  address     = "0.0.0.0:$PORT"
  tls_cert_file = "$config_path/tls/cert.pem"
  tls_key_file  = "$config_path/tls/key.pem"
}

ui = true

api_addr = "https://$DOMAIN:$PORT"
cluster_addr = "https://$DOMAIN:$CLUSTER_PORT"
EOF

  chmod 600 "$config_path/vault.hcl"
  mkdir -p "$config_path/tls"
  cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem "$config_path/tls/cert.pem"
  cp /etc/letsencrypt/live/$DOMAIN/privkey.pem "$config_path/tls/key.pem"
  chmod 600 $config_path/tls/*

}



setup_vault_service() {
  local config_path="$VAULT_BASE_PATH/$INSTANCE_NAME"
  local service_file="$VAULT_SERVICE_BASE_FILE-$INSTANCE_NAME.service"

  if [ -f "$service_file" ]; then
    echo "Vault service for instance '$INSTANCE_NAME' is already configured."
    return
  fi

  echo "Setting up Vault service for instance '$INSTANCE_NAME'..."
  cat > "$service_file" <<EOF
[Unit]
Description=HashiCorp Vault Instance - $INSTANCE_NAME
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
User=root
Group=root
ExecStart=$VAULT_BIN_PATH server -config=$VAULT_BASE_PATH/$INSTANCE_NAME/vault.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

  chmod 644 "$service_file"
  systemctl daemon-reload
  systemctl enable "vault-$INSTANCE_NAME"
  systemctl start "vault-$INSTANCE_NAME"
}

initialize_and_unseal_vault() {
  local config_path="$VAULT_BASE_PATH/$INSTANCE_NAME"
  local data_path="$VAULT_DATA_BASE_PATH/$INSTANCE_NAME"

  export VAULT_ADDR="https://$DOMAIN:$PORT"
  sleep 5
  if [ -f "$data_path/initialized" ]; then
    echo "Vault instance '$INSTANCE_NAME' is already initialized and unsealed."
    return
  fi

  echo "Initializing Vault instance '$INSTANCE_NAME'..."
  INIT_OUTPUT=$(vault operator init -key-shares=5 -key-threshold=3 -format=json -address="https://$DOMAIN:$PORT")

  ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')
  UNSEAL_KEYS=$(echo "$INIT_OUTPUT" | jq -c '.unseal_keys_b64')

  echo "Unsealing Vault instance '$INSTANCE_NAME'..."
  for i in $(seq 0 2); do
    UNSEAL_KEY=$(echo "$UNSEAL_KEYS" | jq -r ".[$i]")
    vault operator unseal "$UNSEAL_KEY"
  done

  echo "Storing root token and unseal keys securely for instance '$INSTANCE_NAME'..."
  echo "$ROOT_TOKEN" > "$config_path/root_token"
  echo "$UNSEAL_KEYS" > "$config_path/unseal_keys"

  chmod 600 "$config_path/root_token" "$config_path/unseal_keys"
  touch "$data_path/initialized"
}

# Main script
install_dependencies
install_vault
configure_vault
setup_vault_service
initialize_and_unseal_vault

echo "Vault instance '$INSTANCE_NAME' has been installed and configured."