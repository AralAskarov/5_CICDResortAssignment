#!/bin/bash

INSTANCE_NAME=$1

sudo systemctl stop vault-$INSTANCE_NAME

sudo rm -f /etc/systemd/system/vault-$INSTANCE_NAME.service

sudo systemctl daemon-reload

sudo rm -f /usr/local/bin/vault

sudo rm -rf /etc/vault/$INSTANCE_NAME

sudo rm -rf /var/lib/vault/$INSTANCE_NAME

sudo rm -rf /etc/vault/$INSTANCE_NAME/tls

sudo rm -rf /var/log/vault/$INSTANCE_NAME
