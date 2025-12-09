import json
import sys

# Args
input_file = sys.argv[1]
output_file = sys.argv[2]

v1_addr = sys.argv[3]
v1_babe = sys.argv[4]
v1_gran = sys.argv[5]
v1_imon = sys.argv[6]
v1_audi = sys.argv[7]

v2_addr = sys.argv[8]
v2_babe = sys.argv[9]
v2_gran = sys.argv[10]
v2_imon = sys.argv[11]
v2_audi = sys.argv[12]

v3_addr = sys.argv[13]
v3_babe = sys.argv[14]
v3_gran = sys.argv[15]
v3_imon = sys.argv[16]
v3_audi = sys.argv[17]

# Load JSON
with open(input_file, "r") as f:
    spec = json.load(f)

# SAFE integer amount
AMOUNT = 100000000000000000000000000
STAKE  = 1000000000000000000000000

# ---------------------------------------------------------
# Update balances
# ---------------------------------------------------------
balances = spec["genesis"]["runtimeGenesis"]["patch"]["balances"]["balances"]

balances.append([v1_addr, AMOUNT])
balances.append([v2_addr, AMOUNT])
balances.append([v3_addr, AMOUNT])

# ---------------------------------------------------------
# Update session keys
# ---------------------------------------------------------
spec["genesis"]["runtimeGenesis"]["patch"]["session"]["keys"] = [
    [v1_addr, v1_addr, {
        "authority_discovery": v1_audi,
        "babe": v1_babe,
        "grandpa": v1_gran,
        "im_online": v1_imon
    }],
    [v2_addr, v2_addr, {
        "authority_discovery": v2_audi,
        "babe": v2_babe,
        "grandpa": v2_gran,
        "im_online": v2_imon
    }],
    [v3_addr, v3_addr, {
        "authority_discovery": v3_audi,
        "babe": v3_babe,
        "grandpa": v3_gran,
        "im_online": v3_imon
    }],
]

# ---------------------------------------------------------
# Update staking
# ---------------------------------------------------------
spec["genesis"]["runtimeGenesis"]["patch"]["staking"]["invulnerables"] = [
    v1_addr, v2_addr, v3_addr
]

spec["genesis"]["runtimeGenesis"]["patch"]["staking"]["stakers"] = [
    [v1_addr, v1_addr, STAKE, "Validator"],
    [v2_addr, v2_addr, STAKE, "Validator"],
    [v3_addr, v3_addr, STAKE, "Validator"],
]

# Write updated JSON
with open(output_file, "w") as f:
    json.dump(spec, f, indent=2)

print("Spec updated:", output_file)
