#!/usr/bin/env bash
set -e

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --v1_addr) V1_ADDR="$2"; shift ;;
    --v1_sec)  V1_SEED="$2"; shift ;;
    --v2_addr) V2_ADDR="$2"; shift ;;
    --v2_sec)  V2_SEED="$2"; shift ;;
    --v3_addr) V3_ADDR="$2"; shift ;;
    --v3_sec)  V3_SEED="$2"; shift ;;
    --input)   INPUT_SPEC="$2"; shift ;;
    --output)  OUTPUT_SPEC="$2"; shift ;;
    *) echo "Unknown param $1"; exit 1 ;;
  esac
  shift
done

derive () {
  reef-node key inspect --scheme $2 "$1" --output-type json \
    | grep -o "\"ss58Address\": \"[^\"]*\"" \
    | cut -d'"' -f4
}

echo "Deriving session keys..."

V1_BABE=$(derive "$V1_SEED//babe" Sr25519)
V1_GRAN=$(derive "$V1_SEED//grandpa" Ed25519)
V1_IMON=$(derive "$V1_SEED//im_online" Sr25519)
V1_AUDI=$(derive "$V1_SEED//authority_discovery" Sr25519)

V2_BABE=$(derive "$V2_SEED//babe" Sr25519)
V2_GRAN=$(derive "$V2_SEED//grandpa" Ed25519)
V2_IMON=$(derive "$V2_SEED//im_online" Sr25519)
V2_AUDI=$(derive "$V2_SEED//authority_discovery" Sr25519)

V3_BABE=$(derive "$V3_SEED//babe" Sr25519)
V3_GRAN=$(derive "$V3_SEED//grandpa" Ed25519)
V3_IMON=$(derive "$V3_SEED//im_online" Sr25519)
V3_AUDI=$(derive "$V3_SEED//authority_discovery" Sr25519)

python3 /workspace/scripts/update-spec.py \
  "$INPUT_SPEC" "$OUTPUT_SPEC" \
  "$V1_ADDR" "$V1_BABE" "$V1_GRAN" "$V1_IMON" "$V1_AUDI" \
  "$V2_ADDR" "$V2_BABE" "$V2_GRAN" "$V2_IMON" "$V2_AUDI" \
  "$V3_ADDR" "$V3_BABE" "$V3_GRAN" "$V3_IMON" "$V3_AUDI"
