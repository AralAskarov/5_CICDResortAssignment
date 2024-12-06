![image](https://github.com/user-attachments/assets/586a3cb6-2064-4d5b-9da0-f3ad314267cf)



web ui on https://vault.medhelper.xyz:8200

to run script write like

    sudo ./install_vault.sh Name port clusterPort domen

usage example

    sudo ./install_vault.sh transit 9200 9201 vault.medhelper.xyz

to see Token use 
```bash
sudo cat /etc/vault/NAME/root_token
```

in script we create 5 unseal keys. to see them use

```bash
sudo cat /etc/vault/NAME/unseal_keys
```

To check status systemd service

    sudo systemctl status vault-NAME.service
