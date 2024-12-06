


Theoretical part

Vault have master key. with that key vault encrypts data. 
The master key is divided into unseal keys; you can determine for yourself how many keys are sufficient to unlock the Vault. Every time we initialize Vault or restart we need to enter these unseal keys.
You can make the primary vault unlocked through the second transit vault. The master key will be encrypted via the transit key and each time Primary Volt will decrypt the key via the transit vault

Primary vault run on https://vault.medhelper.xyz:8200/ui/vault/dashboard

Transit vault run on https://vault.medhelper.xyz:9200/ui/vault/dashboard
