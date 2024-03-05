#!/bin/bash

# Check if the Vault container is already running
if docker ps -a --filter "name=vault" | grep -q 'Up'; then
    echo "Vault container is already running. Skipping start."
else
    echo "Starting Vault container..."
    docker-compose up vault -d
    # bash setup_vault.sh docker-compose.yml vault
fi

# Correctly extract unseal keys from keys.txt
KEY1=$(awk '/Unseal Key 1:/ {print $4}' keys.txt)
KEY2=$(awk '/Unseal Key 2:/ {print $4}' keys.txt)
KEY3=$(awk '/Unseal Key 3:/ {print $4}' keys.txt)

# Print the unseal keys
echo "Unseal Key 1: $KEY1"
echo "Unseal Key 2: $KEY2"
echo "Unseal Key 3: $KEY3"

# Correctly extract the Vault token from keys.txt
VAULT_TOKEN=$(awk '/Initial Root Token:/ {print $4}' keys.txt)

# Print the Vault token
echo "Vault Token: $VAULT_TOKEN"

    
# Unseal the Vault
echo "Unsealing Vault..."
docker-compose exec -T vault vault operator unseal $KEY1
docker-compose exec -T vault vault operator unseal $KEY2
docker-compose exec -T vault vault operator unseal $KEY3

# Enable the KV secrets engine
echo "Enabling KV secrets engine..."
docker-compose exec -e VAULT_TOKEN=$VAULT_TOKEN -T vault vault secrets enable -path=kv kv-v2
# echo "VAULT_TOKEN=hvs.ubAeQf0e5GMFJNjauy1KYaCa" >> .en
echo "Vault Token: $VAULT_TOKEN"

echo "Updating .env file with new VAULT_TOKEN value..."
sed -i '' "s/^VAULT_TOKEN=.*/VAULT_TOKEN=$VAULT_TOKEN/" .env
cat .env
docker-compose down identity
docker-compose up -d -e VAULT_TOKEN=$VAULT_TOKEN identity

# Start the identity and credential schema services
echo "Starting identity and credential schema services..."
docker-compose up credential schema -d

echo "Restart process completed."