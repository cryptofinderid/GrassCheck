#!/bin/bash

if [ ! -f "grass.txt" ]; then
    echo "File grass.txt tidak ditemukan. Pastikan file ada di direktori yang sama dengan grass.sh."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq tidak ditemukan. Menginstal jq..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y jq
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install jq
    else
        echo "Sistem operasi tidak didukung. Silakan instal jq secara manual."
        exit 1
    fi
fi

while IFS= read -r WALLET_ADDRESS; do
    WALLET_ADDRESS=$(echo "$WALLET_ADDRESS" | xargs)

    if [ -n "$WALLET_ADDRESS" ]; then

        echo "$WALLET_ADDRESS"

        JSON_INPUT=$(printf '{"walletAddress":"%s"}' "$WALLET_ADDRESS" | jq -sRr @uri)

        RESPONSE=$(curl -s "https://api.getgrass.io/airdropAllocationsV2?input=${JSON_INPUT}")

        TOTAL_POINTS=$(echo "$RESPONSE" | jq -r '.result.data | to_entries | sort_by(.value) | reverse | .[] |
          if .key | startswith("closedalpha") then
            "Closed Alpha (Tier " + (.key | split("_") | .[2]) + "): " + (.value | tostring)
          else
            "Epoch " + (.key | split("_") | .[0][5:]) + " (Tier " + (.key | split("_") | .[1]) + "): " + (.value | tostring)
          end' | tee /dev/tty | awk -F': ' '{ sum += $2 } END { print sum }')

        echo "Tokens to Claim: $TOTAL_POINTS"

        echo "============================"

    fi
done < grass.txt
