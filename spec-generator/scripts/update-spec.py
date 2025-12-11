import json
import sys

input_file = sys.argv[1]
output_file = sys.argv[2]

v1_addr, v1_babe, v1_gran, v1_imon, v1_audi = sys.argv[3:8]
v2_addr, v2_babe, v2_gran, v2_imon, v2_audi = sys.argv[8:13]
v3_addr, v3_babe, v3_gran, v3_imon, v3_audi = sys.argv[13:18]

AMOUNT = 100000000000000000000000000
STAKE = 1000000000000000000000000

with open(input_file) as f:
    spec = json.load(f)

balances = spec["genesis"]["runtimeGenesis"]["patch"]["balances"]["balances"]

balances.append([v1_addr, AMOUNT])
balances.append([v2_addr, AMOUNT])
balances.append([v3_addr, AMOUNT])

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

spec["genesis"]["runtimeGenesis"]["patch"]["staking"]["invulnerables"] = [
    v1_addr, v2_addr, v3_addr
]

spec["genesis"]["runtimeGenesis"]["patch"]["staking"]["stakers"] = [
    [v1_addr, v1_addr, STAKE, "Validator"],
    [v2_addr, v2_addr, STAKE, "Validator"],
    [v3_addr, v3_addr, STAKE, "Validator"],
]

with open(output_file, "w") as f:
    json.dump(spec, f, indent=2)

print("Updated spec written to:", output_file)
