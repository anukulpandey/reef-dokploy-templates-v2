#!/usr/bin/env bash
set -euo pipefail

###############################################
#  Local 3-validator Reef network bootstrap  #
###############################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_BIN="reef-node"

echo "=========================================="
echo "Setting up local validator network..."
echo "=========================================="

# Check dependencies
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: 'jq' is required but not installed. Please install jq and retry."
  exit 1
fi

if ! command -v make >/dev/null 2>&1; then
  echo "ERROR: 'make' is required but not installed. Please install make and retry."
  exit 1
fi

echo
echo "[1/9] Starting release binary..."

echo
echo "[2/9] Cleaning up previous chain data..."

rm -rf \
  /tmp/validator1 \
  /tmp/validator2 \
  /tmp/validator3 \
  /tmp/bootnode \
  /tmp/validator1.txt \
  /tmp/validator2.txt \
  /tmp/validator3.txt \
  /tmp/v1_seed.txt \
  /tmp/v2_seed.txt \
  /tmp/v3_seed.txt \
  /tmp/v1_addr.txt \
  /tmp/v2_addr.txt \
  /tmp/v3_addr.txt \
  /tmp/bootnode_peer_id.txt \
  /tmp/bootnode_node_key.txt \
  /tmp/v1_node_key.txt \
  /tmp/v2_node_key.txt \
  /tmp/v3_node_key.txt \
  /tmp/local-chain-spec.json \
  /tmp/local-chain-spec-updated.json \
  /tmp/local-chain-spec-raw.json || true

echo
echo "[3/9] Generating new validator accounts..."

"$NODE_BIN" key generate --scheme Sr25519 --output-type json > /tmp/validator1.txt
"$NODE_BIN" key generate --scheme Sr25519 --output-type json > /tmp/validator2.txt
"$NODE_BIN" key generate --scheme Sr25519 --output-type json > /tmp/validator3.txt

echo
echo "[4/9] Generating random node keys..."

"$NODE_BIN" key generate-node-key --chain local > /tmp/bootnode_node_key.txt
"$NODE_BIN" key generate-node-key --chain local > /tmp/v1_node_key.txt
"$NODE_BIN" key generate-node-key --chain local > /tmp/v2_node_key.txt
"$NODE_BIN" key generate-node-key --chain local > /tmp/v3_node_key.txt

echo
echo "[5/9] Generating and updating chain spec..."

# Base chain spec
"$NODE_BIN" build-spec --chain testnet-new --disable-default-bootnode > /tmp/local-chain-spec.json

# Extract validator seeds and addresses
V1_SEED=$(grep -o '"secretSeed": "[^"]*"' /tmp/validator1.txt | cut -d'"' -f4)
V1_ADDR=$(grep -o '"ss58Address": "[^"]*"' /tmp/validator1.txt | cut -d'"' -f4)

V2_SEED=$(grep -o '"secretSeed": "[^"]*"' /tmp/validator2.txt | cut -d'"' -f4)
V2_ADDR=$(grep -o '"ss58Address": "[^"]*"' /tmp/validator2.txt | cut -d'"' -f4)

V3_SEED=$(grep -o '"secretSeed": "[^"]*"' /tmp/validator3.txt | cut -d'"' -f4)
V3_ADDR=$(grep -o '"ss58Address": "[^"]*"' /tmp/validator3.txt | cut -d'"' -f4)

echo "Validator 1: $V1_ADDR"
echo "Validator 2: $V2_ADDR"
echo "Validator 3: $V3_ADDR"

echo "Deriving session keys..."

# V1 session keys
V1_BABE=$("$NODE_BIN" key inspect --scheme Sr25519 "$V1_SEED//babe" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)
V1_GRAN=$("$NODE_BIN" key inspect --scheme Ed25519 "$V1_SEED//grandpa" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)
V1_IMON=$("$NODE_BIN" key inspect --scheme Sr25519 "$V1_SEED//im_online" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)
V1_AUDI=$("$NODE_BIN" key inspect --scheme Sr25519 "$V1_SEED//authority_discovery" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)

# V2 session keys
V2_BABE=$("$NODE_BIN" key inspect --scheme Sr25519 "$V2_SEED//babe" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)
V2_GRAN=$("$NODE_BIN" key inspect --scheme Ed25519 "$V2_SEED//grandpa" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)
V2_IMON=$("$NODE_BIN" key inspect --scheme Sr25519 "$V2_SEED//im_online" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)
V2_AUDI=$("$NODE_BIN" key inspect --scheme Sr25519 "$V2_SEED//authority_discovery" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)

# V3 session keys
V3_BABE=$("$NODE_BIN" key inspect --scheme Sr25519 "$V3_SEED//babe" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)
V3_GRAN=$("$NODE_BIN" key inspect --scheme Ed25519 "$V3_SEED//grandpa" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)
V3_IMON=$("$NODE_BIN" key inspect --scheme Sr25519 "$V3_SEED//im_online" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)
V3_AUDI=$("$NODE_BIN" key inspect --scheme Sr25519 "$V3_SEED//authority_discovery" --output-type json 2>/dev/null | grep -o '"ss58Address": "[^"]*"' | cut -d'"' -f4)

echo "V1 BABE: $V1_BABE, GRAN: $V1_GRAN, IMON: $V1_IMON, AUDI: $V1_AUDI"
echo "V2 BABE: $V2_BABE, GRAN: $V2_GRAN, IMON: $V2_IMON, AUDI: $V2_AUDI"
echo "V3 BABE: $V3_BABE, GRAN: $V3_GRAN, IMON: $V3_IMON, AUDI: $V3_AUDI"

# Save seeds and addresses
echo "$V1_SEED" > /tmp/v1_seed.txt
echo "$V2_SEED" > /tmp/v2_seed.txt
echo "$V3_SEED" > /tmp/v3_seed.txt

echo "$V1_ADDR" > /tmp/v1_addr.txt
echo "$V2_ADDR" > /tmp/v2_addr.txt
echo "$V3_ADDR" > /tmp/v3_addr.txt

echo "Updating chain spec with balances, session keys, and staking..."

jq ".genesis.runtimeGenesis.patch.balances.balances += [[\"$V1_ADDR\", 100000000000000000000000000], [\"$V2_ADDR\", 100000000000000000000000000], [\"$V3_ADDR\", 100000000000000000000000000]]" /tmp/local-chain-spec.json | \
jq ".genesis.runtimeGenesis.patch.session.keys = [[\"$V1_ADDR\", \"$V1_ADDR\", {\"authority_discovery\": \"$V1_AUDI\", \"babe\": \"$V1_BABE\", \"grandpa\": \"$V1_GRAN\", \"im_online\": \"$V1_IMON\"}], [\"$V2_ADDR\", \"$V2_ADDR\", {\"authority_discovery\": \"$V2_AUDI\", \"babe\": \"$V2_BABE\", \"grandpa\": \"$V2_GRAN\", \"im_online\": \"$V2_IMON\"}], [\"$V3_ADDR\", \"$V3_ADDR\", {\"authority_discovery\": \"$V3_AUDI\", \"babe\": \"$V3_BABE\", \"grandpa\": \"$V3_GRAN\", \"im_online\": \"$V3_IMON\"}]]" | \
jq ".genesis.runtimeGenesis.patch.staking.invulnerables = [\"$V1_ADDR\", \"$V2_ADDR\", \"$V3_ADDR\"]" | \
jq ".genesis.runtimeGenesis.patch.staking.stakers = [[\"$V1_ADDR\", \"$V1_ADDR\", 1000000000000000000000000, \"Validator\"], [\"$V2_ADDR\", \"$V2_ADDR\", 1000000000000000000000000, \"Validator\"], [\"$V3_ADDR\", \"$V3_ADDR\", 1000000000000000000000000, \"Validator\"]]" \
> /tmp/local-chain-spec-updated.json

# Raw spec
"$NODE_BIN" build-spec --chain /tmp/local-chain-spec-updated.json --disable-default-bootnode --raw > /tmp/local-chain-spec-raw.json

echo
echo "[6/9] Inserting keys for Validator 1..."

V1_SEED=$(cat /tmp/v1_seed.txt)
"$NODE_BIN" key insert --base-path /tmp/validator1 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V1_SEED//babe" \
  --key-type babe
"$NODE_BIN" key insert --base-path /tmp/validator1 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Ed25519 \
  --suri "$V1_SEED//grandpa" \
  --key-type gran
"$NODE_BIN" key insert --base-path /tmp/validator1 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V1_SEED//im_online" \
  --key-type imon
"$NODE_BIN" key insert --base-path /tmp/validator1 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V1_SEED//authority_discovery" \
  --key-type audi

echo
echo "[7/9] Inserting keys for Validator 2..."

V2_SEED=$(cat /tmp/v2_seed.txt)
"$NODE_BIN" key insert --base-path /tmp/validator2 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V2_SEED//babe" \
  --key-type babe
"$NODE_BIN" key insert --base-path /tmp/validator2 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Ed25519 \
  --suri "$V2_SEED//grandpa" \
  --key-type gran
"$NODE_BIN" key insert --base-path /tmp/validator2 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V2_SEED//im_online" \
  --key-type imon
"$NODE_BIN" key insert --base-path /tmp/validator2 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V2_SEED//authority_discovery" \
  --key-type audi

echo
echo "[8/9] Inserting keys for Validator 3..."

V3_SEED=$(cat /tmp/v3_seed.txt)
"$NODE_BIN" key insert --base-path /tmp/validator3 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V3_SEED//babe" \
  --key-type babe
"$NODE_BIN" key insert --base-path /tmp/validator3 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Ed25519 \
  --suri "$V3_SEED//grandpa" \
  --key-type gran
"$NODE_BIN" key insert --base-path /tmp/validator3 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V3_SEED//im_online" \
  --key-type imon
"$NODE_BIN" key insert --base-path /tmp/validator3 \
  --chain=/tmp/local-chain-spec-raw.json \
  --scheme Sr25519 \
  --suri "$V3_SEED//authority_discovery" \
  --key-type audi

echo
echo "[9/9] Starting bootnode and validator nodes (in background)..."

BOOTNODE_PEER_ID=$("$NODE_BIN" key inspect-node-key --file /tmp/bootnode_node_key.txt 2>/dev/null | tail -n1)
echo "$BOOTNODE_PEER_ID" > /tmp/bootnode_peer_id.txt

BOOTNODE_MULTIADDR="/ip4/127.0.0.1/tcp/30335/p2p/$BOOTNODE_PEER_ID"

echo
echo "Bootnode will run on:"
echo "  - P2P port: 30335"
echo "  - Peer ID: $BOOTNODE_PEER_ID"
echo
echo "Validator 1 ($V1_ADDR) will run on:"
echo "  - P2P port: 30333"
echo "  - RPC port: 9944"
echo "  - WebSocket: ws://127.0.0.1:9944"
echo
echo "Validator 2 ($V2_ADDR) will run on:"
echo "  - P2P port: 30334"
echo "  - RPC port: 9945"
echo "  - WebSocket: ws://127.0.0.1:9945"
echo
echo "Validator 3 ($V3_ADDR) will run on:"
echo "  - P2P port: 30336"
echo "  - RPC port: 9946"
echo "  - WebSocket: ws://127.0.0.1:9946"

# Start nodes in background (same terminal, different processes)
"$NODE_BIN" \
  --base-path /tmp/bootnode \
  --chain /tmp/local-chain-spec-raw.json \
  --port 30335 \
  --node-key-file /tmp/bootnode_node_key.txt \
  --name Bootnode \
  > /tmp/bootnode.log 2>&1 &

sleep 2

"$NODE_BIN" \
  --base-path /tmp/validator1 \
  --chain /tmp/local-chain-spec-raw.json \
  --port 30333 \
  --rpc-port 9944 \
  --node-key-file /tmp/v1_node_key.txt \
  --bootnodes "$BOOTNODE_MULTIADDR" \
  --validator \
  --rpc-cors all \
  --rpc-methods Unsafe \
  --rpc-external \
  --name Validator1Node \
  > /tmp/validator1.log 2>&1 &

sleep 2

"$NODE_BIN" \
  --base-path /tmp/validator2 \
  --chain /tmp/local-chain-spec-raw.json \
  --port 30334 \
  --rpc-port 9945 \
  --node-key-file /tmp/v2_node_key.txt \
  --bootnodes "$BOOTNODE_MULTIADDR" \
  --validator \
  --rpc-cors all \
  --rpc-methods Unsafe \
  --rpc-external \
  --name Validator2Node \
  > /tmp/validator2.log 2>&1 &

sleep 2

"$NODE_BIN" \
  --base-path /tmp/validator3 \
  --chain /tmp/local-chain-spec-raw.json \
  --port 30336 \
  --rpc-port 9946 \
  --node-key-file /tmp/v3_node_key.txt \
  --bootnodes "$BOOTNODE_MULTIADDR" \
  --validator \
  --rpc-cors all \
  --rpc-methods Unsafe \
  --rpc-external \
  --name Validator3Node \
  > /tmp/validator3.log 2>&1 &

echo
echo "=========================================="
echo "✅ Local validator network started!"
echo "Bootnode ($BOOTNODE_PEER_ID): P2P 127.0.0.1:30335"
echo "Validator 1 ($V1_ADDR): ws://127.0.0.1:9944"
echo "Validator 2 ($V2_ADDR): ws://127.0.0.1:9945"
echo "Validator 3 ($V3_ADDR): ws://127.0.0.1:9946"
echo
echo "Logs:"
echo "  Bootnode:      /tmp/bootnode.log"
echo "  Validator 1:   /tmp/validator1.log"
echo "  Validator 2:   /tmp/validator2.log"
echo "  Validator 3:   /tmp/validator3.log"
echo
echo "Use 'ps aux | grep reef-node' and 'kill <pid>' to stop nodes."
echo "=========================================="