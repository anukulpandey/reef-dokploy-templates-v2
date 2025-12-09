#!/usr/bin/env bash
set -e

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

# ---------------------------------------------------------
# 1️⃣ START A SIMPLE HTTP SERVER TO DOWNLOAD THE RAW SPEC
# ---------------------------------------------------------
echo "🌐 Starting HTTP server on port 8000 to download specs..."
echo "📁 Accessible files:"
ls -lah /output

# Run the HTTP server in background
cd /output
python3 -m http.server 8000 &
HTTP_PID=$!

echo "➡️  Download raw spec at:  http://localhost:8000/local-chain-spec-raw.json"
echo "➡️  HTTP server PID: $HTTP_PID"

# ---------------------------------------------------------
# 2️⃣ GENERATE BOOTNODE KEYS AND START BOOTNODE
# ---------------------------------------------------------
echo "🔑 Generating bootnode key..."
reef-node key generate-node-key --chain local > /tmp/bootnode_node_key.txt
cp /tmp/bootnode_node_key.txt /output/bootnode_node_key.txt

echo "📄 Bootnode key created at /tmp/bootnode_node_key.txt:"
cat /tmp/bootnode_node_key.txt

echo "🚀 Starting Bootnode..."
exec reef-node \
  --base-path /tmp/bootnode \
  --chain /output/local-chain-spec-raw.json \
  --port 30335 \
  --node-key-file /tmp/bootnode_node_key.txt \
  --name Bootnode
