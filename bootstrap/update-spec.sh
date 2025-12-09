#!/usr/bin/env bash
set -e

#
# --- PARAM PARSER ---
#

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

    *)
      echo "❌ Unknown parameter: $1"
      exit 1
      ;;
  esac
  shift
done

# --- VALIDATION ---
if [[ -z "$V1_ADDR" || -z "$V1_SEED" ||
      -z "$V2_ADDR" || -z "$V2_SEED" ||
      -z "$V3_ADDR" || -z "$V3_SEED" ]]; then
  echo "❌ Missing validator params"
  echo "Usage:"
  echo "  ./update-spec.sh --v1_addr <addr> --v1_sec <seed> ..."
  exit 1
fi

if [[ -z "$INPUT_SPEC" || -z "$OUTPUT_SPEC" ]]; then
  echo "❌ Missing --input or --output spec file paths"
  exit 1
fi

if [[ ! -f "$INPUT_SPEC" ]]; then
  echo "❌ Input spec file not found: $INPUT_SPEC"
  exit 1
fi

echo "🔧 Using input spec: $INPUT_SPEC"
echo "📄 Writing updated spec to: $OUTPUT_SPEC"


#
# --- KEY DERIVATION FUNCTION ---
#

derive_keys () {
  local SEED="$1"
  local PREFIX="$2"

  eval ${PREFIX}_BABE=$(reef-node key inspect --scheme Sr25519 "$SEED//babe" --output-type json | grep -o "\"ss58Address\": \"[^\"]*\"" | cut -d'"' -f4)
  eval ${PREFIX}_GRAN=$(reef-node key inspect --scheme Ed25519 "$SEED//grandpa" --output-type json | grep -o "\"ss58Address\": \"[^\"]*\"" | cut -d'"' -f4)
  eval ${PREFIX}_IMON=$(reef-node key inspect --scheme Sr25519 "$SEED//im_online" --output-type json | grep -o "\"ss58Address\": \"[^\"]*\"" | cut -d'"' -f4)
  eval ${PREFIX}_AUDI=$(reef-node key inspect --scheme Sr25519 "$SEED//authority_discovery" --output-type json | grep -o "\"ss58Address\": \"[^\"]*\"" | cut -d'"' -f4)
}

echo "🔑 Deriving validator keys..."

derive_keys "$V1_SEED" "V1"
derive_keys "$V2_SEED" "V2"
derive_keys "$V3_SEED" "V3"


#
# --- APPLY PATCH USING jq ---
#

jq "
  .genesis.runtimeGenesis.patch.balances.balances +=
    [[\"$V1_ADDR\", 100000000000000000000000000],
     [\"$V2_ADDR\", 100000000000000000000000000],
     [\"$V3_ADDR\", 100000000000000000000000000]] |

  .genesis.runtimeGenesis.patch.session.keys =
    [[\"$V1_ADDR\", \"$V1_ADDR\", {\"authority_discovery\": \"$V1_AUDI\", \"babe\": \"$V1_BABE\", \"grandpa\": \"$V1_GRAN\", \"im_online\": \"$V1_IMON\"}],
     [\"$V2_ADDR\", \"$V2_ADDR\", {\"authority_discovery\": \"$V2_AUDI\", \"babe\": \"$V2_BABE\", \"grandpa\": \"$V2_GRAN\", \"im_online\": \"$V2_IMON\"}],
     [\"$V3_ADDR\", \"$V3_ADDR\", {\"authority_discovery\": \"$V3_AUDI\", \"babe\": \"$V3_BABE\", \"grandpa\": \"$V3_GRAN\", \"im_online\": \"$V3_IMON\"}]] |

  .genesis.runtimeGenesis.patch.staking.invulnerables =
    [\"$V1_ADDR\", \"$V2_ADDR\", \"$V3_ADDR\"] |

  .genesis.runtimeGenesis.patch.staking.stakers =
    [[\"$V1_ADDR\", \"$V1_ADDR\", 1000000000000000000000000, \"Validator\"],
     [\"$V2_ADDR\", \"$V2_ADDR\", 1000000000000000000000000, \"Validator\"],
     [\"$V3_ADDR\", \"$V3_ADDR\", 1000000000000000000000000, \"Validator\"]]
" \
"$INPUT_SPEC" > "$OUTPUT_SPEC"

echo "✅ Spec updated successfully!"
echo "👉 Output written to: $OUTPUT_SPEC"
