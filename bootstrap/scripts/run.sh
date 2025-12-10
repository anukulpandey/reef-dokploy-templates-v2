#!/usr/bin/env bash
set -e
echo "here i am"

chmod -R 777 /output

echo "👉 generating plain spec"
reef-node build-spec --chain testnet-new --disable-default-bootnode \
  > /output/local-chain-spec.json

echo "👉 updating spec"
chmod +x /workspace/update-spec.sh
/workspace/update-spec.sh \
  --v1_addr "$V1_ADDR" --v1_sec "$V1_SEED" \
  --v2_addr "$V2_ADDR" --v2_sec "$V2_SEED" \
  --v3_addr "$V3_ADDR" --v3_sec "$V3_SEED" \
  --input /output/local-chain-spec.json \
  --output /output/local-chain-spec-updated.json

echo "👉 generating RAW spec"
reef-node build-spec \
  --chain /output/local-chain-spec-updated.json \
  --disable-default-bootnode --raw \
  > /output/local-chain-spec-raw.json

echo "🎉 RAW spec created at /output/local-chain-spec-raw.json"

echo
echo "Inserting keys for Validator 1..."

reef-node key insert --base-path /tmp/validator1 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V1_SEED//babe" \
  --key-type babe
reef-node key insert --base-path /tmp/validator1 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Ed25519 \
  --suri "$V1_SEED//grandpa" \
  --key-type gran
reef-node key insert --base-path /tmp/validator1 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V1_SEED//im_online" \
  --key-type imon
reef-node key insert --base-path /tmp/validator1 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V1_SEED//authority_discovery" \
  --key-type audi

echo
echo "Inserting keys for Validator 2..."

reef-node key insert --base-path /tmp/validator2 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V2_SEED//babe" \
  --key-type babe
reef-node key insert --base-path /tmp/validator2 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Ed25519 \
  --suri "$V2_SEED//grandpa" \
  --key-type gran
reef-node key insert --base-path /tmp/validator2 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V2_SEED//im_online" \
  --key-type imon
reef-node key insert --base-path /tmp/validator2 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V2_SEED//authority_discovery" \
  --key-type audi

echo
echo "Inserting keys for Validator 3..."

reef-node key insert --base-path /tmp/validator3 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V3_SEED//babe" \
  --key-type babe
reef-node key insert --base-path /tmp/validator3 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Ed25519 \
  --suri "$V3_SEED//grandpa" \
  --key-type gran
reef-node key insert --base-path /tmp/validator3 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V3_SEED//im_online" \
  --key-type imon
reef-node key insert --base-path /tmp/validator3 \
  --chain=/output/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V3_SEED//authority_discovery" \
  --key-type audi
echo

# ---------------------------------------------------------
# 1️⃣ START A SIMPLE HTTP SERVER TO DOWNLOAD THE RAW SPEC
# ---------------------------------------------------------
echo "🌐 Starting HTTP server on port 8000 to download specs..."
echo "📁 Accessible files:"
ls -lah /output

# Run the HTTP server in background
cd /output
python3 -m http.server $PORT &
HTTP_PID=$!

echo "➡️  Download raw spec at:  http://localhost:$PORT/local-chain-spec-raw.json"
echo "➡️  HTTP server PID: $HTTP_PID"

# ---------------------------------------------------------
# 2️⃣ GENERATE BOOTNODE KEYS AND START BOOTNODE
# ---------------------------------------------------------
echo "🔑 Generating bootnode key..."
reef-node key generate-node-key --chain local > /tmp/bootnode_node_key.txt
reef-node key inspect-node-key --file /tmp/bootnode_node_key.txt > /output/bootnode_node_key.txt

echo "📄 Bootnode key created at /tmp/bootnode_node_key.txt:"
cat /tmp/bootnode_node_key.txt

echo "🚀 Starting Bootnode..."
exec reef-node \
  --base-path /tmp/bootnode \
  --chain /output/local-chain-spec-raw.json \
  --port $P2P_PORT \
  --node-key-file /tmp/bootnode_node_key.txt \
  --name Bootnode
