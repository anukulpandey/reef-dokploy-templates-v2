#!/usr/bin/env bash
set -euo pipefail

NODE_BIN=reef-node

echo
echo "========================================"
echo "📥 Downloading spec and bootnode key..."
echo "  SPEC_URL: $SPEC_URL"
echo "  BOOTNODE_NODE_KEY: $BOOTNODE_NODE_KEY"
echo "========================================"
echo

curl -fsSL "$SPEC_URL" -o /tmp/local-chain-spec-raw.json \
  || { echo "ERROR: failed to download SPEC_URL ($SPEC_URL)"; exit 1; }

curl -fsSL "$BOOTNODE_NODE_KEY" -o /tmp/bootnode_node_key.txt \
  || { echo "ERROR: failed to download BOOTNODE_NODE_KEY ($BOOTNODE_NODE_KEY)"; exit 1; }

echo
echo "========================================"
echo "📄 Bootnode key (first 200 bytes):"
echo "----------------------------------------"
# Print safely (first 200 chars) so logs are readable
head -c 200 /tmp/bootnode_node_key.txt | sed -n '1,10p'
echo
echo "----------------------------------------"
echo "(full file is at /tmp/bootnode_node_key.txt inside container)"
echo "========================================"
echo

echo "🔍 Extracting Bootnode Peer ID..."

# Try several extraction methods (safe)
BOOTNODE_PEER_ID=""

# method 1: modern --file option
if command -v $NODE_BIN >/dev/null 2>&1; then
  BOOTNODE_PEER_ID=$($NODE_BIN key inspect-node-key --file /tmp/bootnode_node_key.txt 2>/dev/null | awk '/Peer ID/ {print $3}' || true)
fi

# method 2: positional argument (some builds)
if [ -z "$BOOTNODE_PEER_ID" ] && command -v $NODE_BIN >/dev/null 2>&1; then
  BOOTNODE_PEER_ID=$($NODE_BIN key inspect-node-key /tmp/bootnode_node_key.txt 2>/dev/null | awk '/Peer ID/ {print $3}' || true)
fi

# method 3: try generic 'key inspect' JSON output
if [ -z "$BOOTNODE_PEER_ID" ] && command -v $NODE_BIN >/dev/null 2>&1; then
  BOOTNODE_PEER_ID=$($NODE_BIN key inspect --file /tmp/bootnode_node_key.txt 2>/dev/null | grep -o '"peerId":[[:space:]]*"[^"]*"' | sed -E 's/.*"([^"]*)".*/\1/' || true)
fi

# method 4: if the file *is* just a peer id or some raw string, try reading it
if [ -z "$BOOTNODE_PEER_ID" ]; then
  maybe=$(tr -d '\r\n' < /tmp/bootnode_node_key.txt || true)
  # basic sanity: Peer IDs are usually long base58 strings (use length check)
  if [ -n "$maybe" ] && [ ${#maybe} -gt 20 ]; then
    BOOTNODE_PEER_ID="$maybe"
  fi
fi

if [ -z "$BOOTNODE_PEER_ID" ]; then
  echo "❌ Could not parse BOOTNODE_PEER_ID from /tmp/bootnode_node_key.txt"
  echo "Dumping file for debugging:"
  cat /tmp/bootnode_node_key.txt
  exit 1
fi

echo "✅ BOOTNODE_PEER_ID = $BOOTNODE_PEER_ID"
BOOTNODE_MULTIADDR="/ip4/$BOOTNODE_IP/tcp/30335/p2p/$BOOTNODE_PEER_ID"
echo "✅ BOOTNODE_MULTIADDR = $BOOTNODE_MULTIADDR"
echo

echo "📦 Preparing validator directory..."
mkdir -p /tmp/validator1
chmod 700 /tmp/validator1

echo "🔑 Inserting session keys (babe, grandpa, im_online, authority_discovery)..."
$NODE_BIN key insert --base-path /tmp/validator1 --chain /tmp/local-chain-spec-raw.json \
  --scheme Sr25519 --suri "$V1SEED//babe" --key-type babe

$NODE_BIN key insert --base-path /tmp/validator1 --chain /tmp/local-chain-spec-raw.json \
  --scheme Ed25519 --suri "$V1SEED//grandpa" --key-type gran

$NODE_BIN key insert --base-path /tmp/validator1 --chain /tmp/local-chain-spec-raw.json \
  --scheme Sr25519 --suri "$V1SEED//im_online" --key-type imon

$NODE_BIN key insert --base-path /tmp/validator1 --chain /tmp/local-chain-spec-raw.json \
  --scheme Sr25519 --suri "$V1SEED//authority_discovery" --key-type audi

# create validator node key (this writes a node-key file)
echo "🔑 Generating validator node key..."
$NODE_BIN key generate-node-key --chain local > /tmp/v1_node_key.txt
chmod 600 /tmp/v1_node_key.txt
echo "  -> /tmp/v1_node_key.txt created"

echo
echo "🚀 Starting Validator Node (logs -> /tmp/validator1.log)..."
exec $NODE_BIN \
  --base-path /tmp/validator1 \
  --chain /tmp/local-chain-spec-raw.json \
  --port 30334 \
  --rpc-port 9945 \
  --node-key-file /tmp/v1_node_key.txt \
  --bootnodes "$BOOTNODE_MULTIADDR" \
  --validator \
  --rpc-cors all \
  --rpc-external \
  --rpc-methods Unsafe \
  --name Validator1Node
