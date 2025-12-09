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
  ./output/validator1 \
  ./output/validator2 \
  ./output/validator3 \
  ./output/bootnode \
  ./output/validator1.txt \
  ./output/validator2.txt \
  ./output/validator3.txt \
  ./output/v1_seed.txt \
  ./output/v2_seed.txt \
  ./output/v3_seed.txt \
  ./output/v1_addr.txt \
  ./output/v2_addr.txt \
  ./output/v3_addr.txt \
  ./output/bootnode_peer_id.txt \
  ./output/bootnode_node_key.txt \
  ./output/v1_node_key.txt \
  ./output/v2_node_key.txt \
  ./output/v3_node_key.txt \
  ./output/local-chain-spec.json \
  ./output/local-chain-spec-updated.json \
  ./output/local-chain-spec-raw-2.json || true

echo

echo
echo "[3/9] Generating random node keys..."
mkdir -p ./output

"$NODE_BIN" key generate-node-key --chain local > ./output/bootnode_node_key.txt

echo
echo "[4/9] Generating and updating chain spec..."

# Base chain spec
"$NODE_BIN" build-spec --chain testnet-new --disable-default-bootnode > ./output/local-chain-spec.json

# Extract validator seeds and addresses
V1_SEED=0x4beb11e380012110b0b072fbb3d8e7455921cf4658de06c33d970be82ccf9ed5
V1_ADDR=5GH14oJ4A3VDLoC6nXutsTwS4dMwebDipNdSugD5zFnnWKp5

V2_SEED=0x3348e15287dae612d9c8f008a468ff6c229a55c4b58d778f389cc03134e3efbe
V2_ADDR=5CmKswtRQGFrt3CcP5waJVxgEJfRy1xsmwPLRPWkumLBz8nv

V3_SEED=0xba8ad5d3607f10c356860024a08ea279dbd529f0950fa752fc6c2d59981b89e5
V3_ADDR=5HTmW3wtfs6h1D44QxfLPpwVzQ3Jc7S8eiQAuDRkmqEhrwMQ

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
echo "$V1_SEED" > ./output/v1_seed.txt
echo "$V2_SEED" > ./output/v2_seed.txt
echo "$V3_SEED" > ./output/v3_seed.txt

echo "$V1_ADDR" > ./output/v1_addr.txt
echo "$V2_ADDR" > ./output/v2_addr.txt
echo "$V3_ADDR" > ./output/v3_addr.txt

echo $V1_SEED
echo $V2_SEED
echo $V3_SEED

echo $V1_ADDR
echo $V2_ADDR
echo $V3_ADDR

echo "Updating chain spec with balances, session keys, and staking..."

jq ".genesis.runtimeGenesis.patch.balances.balances += [[\"$V1_ADDR\", 100000000000000000000000000], [\"$V2_ADDR\", 100000000000000000000000000], [\"$V3_ADDR\", 100000000000000000000000000]]" ./output/local-chain-spec.json | \
jq ".genesis.runtimeGenesis.patch.session.keys = [[\"$V1_ADDR\", \"$V1_ADDR\", {\"authority_discovery\": \"$V1_AUDI\", \"babe\": \"$V1_BABE\", \"grandpa\": \"$V1_GRAN\", \"im_online\": \"$V1_IMON\"}], [\"$V2_ADDR\", \"$V2_ADDR\", {\"authority_discovery\": \"$V2_AUDI\", \"babe\": \"$V2_BABE\", \"grandpa\": \"$V2_GRAN\", \"im_online\": \"$V2_IMON\"}], [\"$V3_ADDR\", \"$V3_ADDR\", {\"authority_discovery\": \"$V3_AUDI\", \"babe\": \"$V3_BABE\", \"grandpa\": \"$V3_GRAN\", \"im_online\": \"$V3_IMON\"}]]" | \
jq ".genesis.runtimeGenesis.patch.staking.invulnerables = [\"$V1_ADDR\", \"$V2_ADDR\", \"$V3_ADDR\"]" | \
jq ".genesis.runtimeGenesis.patch.staking.stakers = [[\"$V1_ADDR\", \"$V1_ADDR\", 1000000000000000000000000, \"Validator\"], [\"$V2_ADDR\", \"$V2_ADDR\", 1000000000000000000000000, \"Validator\"], [\"$V3_ADDR\", \"$V3_ADDR\", 1000000000000000000000000, \"Validator\"]]" \
> ./output/local-chain-spec-updated.json

# Raw spec
"$NODE_BIN" build-spec --chain ./output/local-chain-spec-updated.json --disable-default-bootnode --raw > ./output/local-chain-spec-raw-2.json

# echo
# echo "[6/9] Inserting keys for Validator 1..."

# "$NODE_BIN" key insert --base-path ./output/validator1 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Sr25519 \
#   --suri "$V1_SEED//babe" \
#   --key-type babe
# "$NODE_BIN" key insert --base-path ./output/validator1 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Ed25519 \
#   --suri "$V1_SEED//grandpa" \
#   --key-type gran
# "$NODE_BIN" key insert --base-path ./output/validator1 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Sr25519 \
#   --suri "$V1_SEED//im_online" \
#   --key-type imon
# "$NODE_BIN" key insert --base-path ./output/validator1 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Sr25519 \
#   --suri "$V1_SEED//authority_discovery" \
#   --key-type audi

# echo
# echo "[7/9] Inserting keys for Validator 2..."

# "$NODE_BIN" key insert --base-path ./output/validator2 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Sr25519 \
#   --suri "$V2_SEED//babe" \
#   --key-type babe
# "$NODE_BIN" key insert --base-path ./output/validator2 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Ed25519 \
#   --suri "$V2_SEED//grandpa" \
#   --key-type gran
# "$NODE_BIN" key insert --base-path ./output/validator2 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Sr25519 \
#   --suri "$V2_SEED//im_online" \
#   --key-type imon
# "$NODE_BIN" key insert --base-path ./output/validator2 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Sr25519 \
#   --suri "$V2_SEED//authority_discovery" \
#   --key-type audi

# echo
# echo "[8/9] Inserting keys for Validator 3..."

# "$NODE_BIN" key insert --base-path ./output/validator3 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Sr25519 \
#   --suri "$V3_SEED//babe" \
#   --key-type babe
# "$NODE_BIN" key insert --base-path ./output/validator3 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Ed25519 \
#   --suri "$V3_SEED//grandpa" \
#   --key-type gran
# "$NODE_BIN" key insert --base-path ./output/validator3 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Sr25519 \
#   --suri "$V3_SEED//im_online" \
#   --key-type imon
# "$NODE_BIN" key insert --base-path ./output/validator3 \
#   --chain=./output/local-chain-spec-raw-2.json \
#   --scheme Sr25519 \
#   --suri "$V3_SEED//authority_discovery" \
#   --key-type audi

# echo
echo "[9/9] Starting bootnode and validator nodes (in background)..."

BOOTNODE_PEER_ID=$("$NODE_BIN" key inspect-node-key --file ./output/bootnode_node_key.txt 2>/dev/null | tail -n1)
echo "$BOOTNODE_PEER_ID" > ./output/bootnode_peer_id.txt

BOOTNODE_MULTIADDR="/ip4/127.0.0.1/tcp/30335/p2p/$BOOTNODE_PEER_ID"

echo
echo "Bootnode will run on:"
echo "  - P2P port: 30335"
echo "  - Peer ID: $BOOTNODE_PEER_ID"
echo

# Start nodes in background (same terminal, different processes)
"$NODE_BIN" \
  --base-path ./output/bootnode \
  --chain ./output/local-chain-spec-raw-2.json \
  --port 30335 \
  --node-key-file ./output/bootnode_node_key.txt \
  --name Bootnode 
