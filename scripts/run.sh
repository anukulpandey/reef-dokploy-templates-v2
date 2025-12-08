#!/usr/bin/env bash
set -e

chmod 777 /output

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

echo "👉 generating RAW spec";
reef-node build-spec --chain /output/local-chain-spec-updated.json --disable-default-bootnode --raw > /output/local-chain-spec-raw.json;

echo "🎉 DONE!"
