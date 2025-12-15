#!/usr/bin/env bash
set -euo pipefail

NODE_BIN=reef-node

echo
echo "========================================"
echo "📥 Downloading spec and bootnode key..."
echo "========================================"
echo

# Download spec
wget -q -O /tmp/local-chain-spec-raw.json "$SPEC_URL" \
  || { echo "ERROR: failed to download SPEC_URL ($SPEC_URL)"; exit 1; }

# Download bootnode key
wget -q -O /tmp/bootnode_node_key.txt "$BOOTNODE_NODE_KEY" \
  || { echo "ERROR: failed to download BOOTNODE_NODE_KEY ($BOOTNODE_NODE_KEY)"; exit 1; }

echo "🔍 Extracting Bootnode Peer ID..."

BOOTNODE_PEER_ID=""

if command -v $NODE_BIN >/dev/null 2>&1; then
  BOOTNODE_PEER_ID=$(
    $NODE_BIN key inspect-node-key --file /tmp/bootnode_node_key.txt 2>/dev/null \
    | awk '/Peer ID/ {print $3}' || true
  )
fi

if [ -z "$BOOTNODE_PEER_ID" ]; then
  echo "❌ Could not extract BOOTNODE_PEER_ID"
  exit 1
fi

BOOTNODE_MULTIADDR="/ip4/$BOOTNODE_IP/tcp/30335/p2p/$BOOTNODE_PEER_ID"

echo "✅ BOOTNODE_MULTIADDR = $BOOTNODE_MULTIADDR"
echo

echo "📦 Preparing RPC node directory..."
mkdir -p /tmp/rpc-node
chmod 700 /tmp/rpc-node

echo "🔑 Generating node key..."
$NODE_BIN key generate-node-key --chain local > /tmp/rpc_node_key.txt
chmod 600 /tmp/rpc_node_key.txt

echo
echo "🚀 Starting RPC-only node..."
echo "   RPC : 0.0.0.0:$RPC_PORT"
echo

exec $NODE_BIN \
  --base-path /tmp/rpc-node \
  --chain /tmp/local-chain-spec-raw.json \
  --port $P2P_PORT \
  --node-key-file /tmp/rpc_node_key.txt \
  --bootnodes "$BOOTNODE_MULTIADDR" \
  --rpc-external \
  --rpc-port $RPC_PORT \
  --rpc-cors all \
  --rpc-methods unsafe \
  --name "$NODE_NAME"
