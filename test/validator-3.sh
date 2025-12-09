#!/usr/bin/env bash
set -euo pipefail

NODE_BIN=reef-node
SPEC_URL=http://192.168.31.69:8000/local-chain-spec-raw.json
BOOTNODE_NODE_KEY=http://192.168.31.69:8000/bootnode_node_key.txt
BOOTNODE_IP=192.168.31.69
V1SEED=0xba8ad5d3607f10c356860024a08ea279dbd529f0950fa752fc6c2d59981b89e5
V1ADDR=5HTmW3wtfs6h1D44QxfLPpwVzQ3Jc7S8eiQAuDRkmqEhrwMQ

echo
echo "========================================"
echo "📥 Downloading spec and bootnode key..."
echo "  SPEC_URL: $SPEC_URL"
echo "  BOOTNODE_NODE_KEY: $BOOTNODE_NODE_KEY"
echo "========================================"
echo

# curl -fsSL "$SPEC_URL" -o ./output/local-chain-spec-raw.json \
#   || { echo "ERROR: failed to download SPEC_URL ($SPEC_URL)"; exit 1; }

# curl -fsSL "$BOOTNODE_NODE_KEY" -o ./output/bootnode_node_key.txt \
#   || { echo "ERROR: failed to download BOOTNODE_NODE_KEY ($BOOTNODE_NODE_KEY)"; exit 1; }

# echo
# echo "========================================"
# echo "📄 Bootnode key (first 200 bytes):"
# echo "----------------------------------------"
# # Print safely (first 200 chars) so logs are readable
# head -c 200 ./output/bootnode_node_key.txt | sed -n '1,10p'
# echo
# echo "----------------------------------------"
# echo "(full file is at ./output/bootnode_node_key.txt inside container)"
# echo "========================================"
# echo

# echo "🔍 Extracting Bootnode Peer ID..."

# Try several extraction methods (safe)
BOOTNODE_PEER_ID=""

# method 1: modern --file option
if command -v $NODE_BIN >/dev/null 2>&1; then
  BOOTNODE_PEER_ID=$($NODE_BIN key inspect-node-key --file ./output/bootnode_node_key.txt 2>/dev/null | awk '/Peer ID/ {print $3}' || true)
fi

# method 2: positional argument (some builds)
if [ -z "$BOOTNODE_PEER_ID" ] && command -v $NODE_BIN >/dev/null 2>&1; then
  BOOTNODE_PEER_ID=$($NODE_BIN key inspect-node-key ./output/bootnode_node_key.txt 2>/dev/null | awk '/Peer ID/ {print $3}' || true)
fi

# method 3: try generic 'key inspect' JSON output
if [ -z "$BOOTNODE_PEER_ID" ] && command -v $NODE_BIN >/dev/null 2>&1; then
  BOOTNODE_PEER_ID=$($NODE_BIN key inspect --file ./output/bootnode_node_key.txt 2>/dev/null | grep -o '"peerId":[[:space:]]*"[^"]*"' | sed -E 's/.*"([^"]*)".*/\1/' || true)
fi

# method 4: if the file *is* just a peer id or some raw string, try reading it
if [ -z "$BOOTNODE_PEER_ID" ]; then
  maybe=$(tr -d '\r\n' < ./output/bootnode_node_key.txt || true)
  # basic sanity: Peer IDs are usually long base58 strings (use length check)
  if [ -n "$maybe" ] && [ ${#maybe} -gt 20 ]; then
    BOOTNODE_PEER_ID="$maybe"
  fi
fi

if [ -z "$BOOTNODE_PEER_ID" ]; then
  echo "❌ Could not parse BOOTNODE_PEER_ID from ./output/bootnode_node_key.txt"
  echo "Dumping file for debugging:"
  cat ./output/bootnode_node_key.txt
  exit 1
fi

echo "✅ BOOTNODE_PEER_ID = $BOOTNODE_PEER_ID"
BOOTNODE_MULTIADDR="/ip4/$BOOTNODE_IP/tcp/30335/p2p/12D3KooWHqCWbiLV5pKNm27NV6Cn3nswYkvntFXeuw5o2pjtU4PL"
echo "✅ BOOTNODE_MULTIADDR = $BOOTNODE_MULTIADDR"
echo

echo "📦 Preparing validator directory..."
mkdir -p ./output/validator3
chmod 700 ./output/validator3

echo "🔑 Inserting session keys (babe, grandpa, im_online, authority_discovery)..."
$NODE_BIN key insert --base-path ./output/validator3 --chain ./output/local-chain-spec-raw-2.json \
  --scheme Sr25519 --suri "$V1SEED//babe" --key-type babe

$NODE_BIN key insert --base-path ./output/validator3 --chain ./output/local-chain-spec-raw-2.json \
  --scheme Ed25519 --suri "$V1SEED//grandpa" --key-type gran

$NODE_BIN key insert --base-path ./output/validator3 --chain ./output/local-chain-spec-raw-2.json \
  --scheme Sr25519 --suri "$V1SEED//im_online" --key-type imon

$NODE_BIN key insert --base-path ./output/validator3 --chain ./output/local-chain-spec-raw-2.json \
  --scheme Sr25519 --suri "$V1SEED//authority_discovery" --key-type audi

# create validator node key (this writes a node-key file)
echo "🔑 Generating validator node key..."
$NODE_BIN key generate-node-key --chain local > ./output/v1_node_key.txt
chmod 600 ./output/v1_node_key.txt
echo "  -> ./output/v1_node_key.txt created"

echo
echo "🚀 Starting Validator Node (logs -> ./output/validator3.log)..."
exec $NODE_BIN \
  --base-path ./output/validator3 \
  --chain ./output/local-chain-spec-raw-2.json \
  --port 30336 \
  --rpc-port 9946 \
  --node-key-file ./output/v1_node_key.txt \
  --bootnodes "$BOOTNODE_MULTIADDR" \
  --validator \
  --rpc-cors all \
  --rpc-external \
  --rpc-methods Unsafe \
  --name validator3Node
