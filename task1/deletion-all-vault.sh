#!/bin/bash

sudo systemctl stop vault

sudo rm -f /etc/systemd/system/vault.service

sudo systemctl daemon-reload

sudo rm -f /usr/local/bin/vault

sudo rm -rf /etc/vault

sudo rm -rf /var/lib/vault

sudo rm -rf /etc/vault/tls

sudo rm -rf /var/log/vault

