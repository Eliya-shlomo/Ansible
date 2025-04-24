#!/bin/bash
echo "[web]" > inventory.ini

for ip in $(terraform output -json instance_ips | jq -r '.[]'); do
  echo "$ip ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my-key.pem" >> inventory.ini
done