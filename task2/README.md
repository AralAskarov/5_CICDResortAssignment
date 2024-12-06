## Task #2. Auto-unseal
Configure Vault to auto-unseal using the transit secrets engine method. This
involves setting up a secondary Vault instance that acts as a Transit auto-unseal
server. You can install vault either on a secondary server or as a separate instance on
the same server.
Both Vault instances should be installed using script from task #1.


Theoretical part

Vault have master key. with that key vault encrypts data. 
The master key is divided into unseal keys; you can determine for yourself how many keys are sufficient to unlock the Vault. Every time we initialize Vault or restart we need to enter these unseal keys.
You can make the primary vault unlocked through the second transit vault. The master key will be encrypted via the transit key and each time Primary Volt will decrypt the key via the transit vault

Primary vault run on https://vault.medhelper.xyz:8200/ui/vault/dashboard

Transit vault run on https://vault.medhelper.xyz:9200/ui/vault/dashboard


### 1 go to transit vault
```bash
export VAULT_ADDR="https://vault.medhelper.xyz:9200"
vault status
```
### 2 Enable Transit Secrets Engine: Activate Transit Secrets Engine on Secondary Vault

vault secrets enable transit

expected result 
```bash
vault secrets enable transit
Success! Enabled the transit secrets engine at: transit/
```

### 3 Create Transit Key: Create a key that will be used to encrypt/decrypt Primary Vault data:
```bash
vault write -f transit/keys/autounseal
```

Expected result
```bash
vault write -f transit/keys/autounseal
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1733493982]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      autounseal
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
```
### 4 Make sure the key has been created:
```bash
vault list transit/keys
```
expected tesult
Keys
----
autounseal



### 5 Allow access to Transit Key: Configure a policy to allow Primary Vault to use this key:
```bash
cat <<EOF | vault policy write autounseal -
path "transit/encrypt/autounseal" {
  capabilities = ["update"]
}

path "transit/decrypt/autounseal" {
  capabilities = ["update"]
}
EOF
```

Expected result
Success! Uploaded policy: autounseal


### 6 Create a token with this policy that will use Primary Vault:
vault token create -policy="autounseal" -period=24h

Expected result

Key                  Value
---                  -----
token                hvs.CAESILcxxxxxxxxxxxxxxxxxx
token_accessor       OwIzymVFPFWPdAmQotNvq5jx
token_duration       24h
token_renewable      true
token_policies       ["autounseal" "default"]
identity_policies    []
policies             ["autounseal" "default"]

### remember this token


### 7 Go as primary vault
```bash
export VAULT_ADDR="https://vault.medhelper.xyz:8200"
vault login <ROOT_TOKEN_PRIMARY>
```

### 8 add new block to config hcl (/etc/vault/primary/vault.hcl)

```bash
seal "transit" {
  address            = "https://vault.medhelper.xyz:9200"
  token              = "<TRANSIT_TOKEN>" 
  key_name           = "autounseal"
  mount_path         = "transit/"
  tls_skip_verify    = false 
}
```

### 9 restart vault
```bash
sudo systemctl restart vault-primary.service
```
But if you go to ui, vault will require unseal keys, its because you need to apply
### 10 To apply you need to log in once using unseal keys via migrate command
```bash
vault operator unseal -migrate
vault operator unseal -migrate
vault operator unseal -migrate
```

### 11 restart again 
```bash
sudo systemctl restart vault-primary.service
```

Then there will be no require unseal keys if you restart
