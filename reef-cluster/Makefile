PHONY: configure-rust
configure-rust:
	rustup toolchain install nightly
	rustup target add wasm32-unknown-unknown --toolchain nightly
	rustup component add clippy

.PHONY: init
init:
	make configure-rust

.PHONY: wasm
wasm:
	cargo build -p reef-runtime --features with-ethereum-compatibility --release

.PHONY: check
check:
	SKIP_WASM_BUILD=1 cargo check

.PHONY: clippy
clippy:
	SKIP_WASM_BUILD=1 cargo clippy -- -D warnings -A clippy::from-over-into -A clippy::unnecessary-cast -A clippy::identity-op -A clippy::upper-case-acronyms

.PHONY: watch
watch:
	SKIP_WASM_BUILD=1 cargo watch -c -x build

.PHONY: test
test:
	SKIP_WASM_BUILD=1 cargo test --features with-ethereum-compatibility --all
	SKIP_WASM_BUILD=1 cargo test --all

.PHONY: test-print
test-print:
	SKIP_WASM_BUILD=1 cargo test --features with-ethereum-compatibility --all -- --nocapture
	SKIP_WASM_BUILD=1 cargo test --all -- --nocapture

.PHONY: debug
debug:
	cargo build && RUST_LOG=debug RUST_BACKTRACE=1 rust-gdb --args target/debug/reef-node --dev --tmp -lruntime=debug

.PHONY: run
run:
	RUST_BACKTRACE=1 cargo run --manifest-path node/Cargo.toml --features with-ethereum-compatibility  -- --dev --tmp

.PHONY: log
log:
	RUST_BACKTRACE=1 RUST_LOG=debug cargo run --manifest-path node/Cargo.toml --features with-ethereum-compatibility  -- --dev --tmp

.PHONY: noeth
noeth:
	RUST_BACKTRACE=1 cargo run -- --dev --tmp

.PHONY: bench
bench:
	SKIP_WASM_BUILD=1 cargo test --manifest-path node/Cargo.toml --features runtime-benchmarks,with-ethereum-compatibility benchmarking

.PHONY: doc
doc:
	SKIP_WASM_BUILD=1 cargo doc --open

.PHONY: cargo-update
cargo-update:
	cargo update
	cargo update --manifest-path node/Cargo.toml
	make test

.PHONY: fork
fork:
	npm i --prefix fork fork
ifeq (,$(wildcard fork/data))
	mkdir fork/data
endif
	cp target/release/reef-node fork/data/binary
	cp target/release/wbuild/reef-runtime/reef_runtime.compact.wasm fork/data/runtime.wasm
	cp assets/types.json fork/data/schema.json
	cp assets/chain_spec_$(chain)_raw.json fork/data/genesis.json
	cd fork && npm start && cd ..

.PHONY: run-local
run-local:
	@echo "=========================================="
	@echo " Setting up local validator network..."
	@echo "=========================================="

	@echo "\n[1/7] Cleaning old data..."
	@rm -rf /tmp/validator1 /tmp/validator2 /tmp/validator3 /tmp/bootnode \
	/tmp/*.txt /tmp/local-chain-spec-raw.json /workspace/download

	@mkdir -p /workspace/download

	@echo "\n[2/7] Writing validator seeds + addresses from ENV..."

	@if [ -z "$$v1sec" ] || [ -z "$$v2sec" ] || [ -z "$$v3sec" ] || \
	     [ -z "$$v1addr" ] || [ -z "$$v2addr" ] || [ -z "$$v3addr" ]; then \
		echo "❌ ERROR: Missing one or more required ENV variables:"; \
		echo "   v1sec v2sec v3sec v1addr v2addr v3addr"; \
		exit 1; \
	fi

	@echo "$$v1sec"  > /tmp/v1_seed.txt
	@echo "$$v2sec"  > /tmp/v2_seed.txt
	@echo "$$v3sec"  > /tmp/v3_seed.txt

	@echo "$$v1addr" > /tmp/v1_addr.txt
	@echo "$$v2addr" > /tmp/v2_addr.txt
	@echo "$$v3addr" > /tmp/v3_addr.txt

	@echo "\n[3/7] Calling API to generate RAW spec…"

	@curl -s \
	"$$specgenurl/generate?v1addr=$$(cat /tmp/v1_addr.txt)&v1seed=$$(cat /tmp/v1_seed.txt)&v2addr=$$(cat /tmp/v2_addr.txt)&v2seed=$$(cat /tmp/v2_seed.txt)&v3addr=$$(cat /tmp/v3_addr.txt)&v3seed=$$(cat /tmp/v3_seed.txt)" \
	> /tmp/gen.json || { echo "❌ API call failed"; exit 1; }

	@echo "API Response:"
	@cat /tmp/gen.json

	@echo "\n[4/7] Extracting raw_spec_url…"

	@RAW_URL=$$(jq -r '.raw_spec_url' /tmp/gen.json); \
	if [ "$$RAW_URL" = "null" ] || [ -z "$$RAW_URL" ]; then \
		echo "❌ raw_spec_url missing in response"; exit 1; \
	fi; \
	echo "RAW URL = $$RAW_URL" > /tmp/raw_url.txt

	@echo "[5/7] Downloading RAW spec…"

	@URL=$$(jq -r '.raw_spec_url' /tmp/gen.json); \
	echo "Downloading: $$URL"; \
	for i in 1 2 3 4 5 6 7 8 9 10; do \
		wget -q -O /tmp/local-chain-spec-raw.json "$$URL" && break; \
		echo "  Retry $$i: File not ready yet..."; \
		sleep 1; \
	done; \
	if [ ! -s /tmp/local-chain-spec-raw.json ]; then \
		echo "❌ Failed downloading raw spec after retries"; \
		exit 1; \
	fi

	@echo "✅ RAW spec downloaded"

	@cp /tmp/local-chain-spec-raw.json /workspace/download/local-chain-spec-raw.json
	@echo "✅ RAW spec copied to /workspace/download/"


	@echo "\n[5.5/7] Exposing RAW spec via HTTP (port 8001)…"
	@nohup python3 -m http.server 8001 \
	--bind 0.0.0.0 \
	--directory /workspace/download \
	> /workspace/download/spec-server.log 2>&1 &
	@echo "✅ Spec server running at http://0.0.0.0:8001/local-chain-spec-raw.json"

	@echo "\n[6/7] Generating node keys…"
	@./target/release/reef-node key generate-node-key --chain local > /tmp/bootnode_node_key.txt
	@./target/release/reef-node key generate-node-key --chain local > /tmp/v1_node_key.txt
	@./target/release/reef-node key generate-node-key --chain local > /tmp/v2_node_key.txt
	@./target/release/reef-node key generate-node-key --chain local > /tmp/v3_node_key.txt

	@./target/release/reef-node key inspect-node-key --file /tmp/bootnode_node_key.txt > /workspace/download/bootnode_node_key.txt

	@echo "\n[7/7] Inserting session keys…"

	@bash -c '\
		V1_SEED=$$(cat /tmp/v1_seed.txt); \
		V2_SEED=$$(cat /tmp/v2_seed.txt); \
		V3_SEED=$$(cat /tmp/v3_seed.txt); \
		\
		echo "→ Validator 1"; \
		./target/release/reef-node key insert --base-path /tmp/validator1 --chain /tmp/local-chain-spec-raw.json --scheme Sr25519 --suri "$$V1_SEED//babe" --key-type babe; \
		./target/release/reef-node key insert --base-path /tmp/validator1 --chain /tmp/local-chain-spec-raw.json --scheme Ed25519 --suri "$$V1_SEED//grandpa" --key-type gran; \
		./target/release/reef-node key insert --base-path /tmp/validator1 --chain /tmp/local-chain-spec-raw.json --scheme Sr25519 --suri "$$V1_SEED//im_online" --key-type imon; \
		./target/release/reef-node key insert --base-path /tmp/validator1 --chain /tmp/local-chain-spec-raw.json --scheme Sr25519 --suri "$$V1_SEED//authority_discovery" --key-type audi; \
		\
		echo "→ Validator 2"; \
		./target/release/reef-node key insert --base-path /tmp/validator2 --chain /tmp/local-chain-spec-raw.json --scheme Sr25519 --suri "$$V2_SEED//babe" --key-type babe; \
		./target/release/reef-node key insert --base-path /tmp/validator2 --chain /tmp/local-chain-spec-raw.json --scheme Ed25519 --suri "$$V2_SEED//grandpa" --key-type gran; \
		./target/release/reef-node key insert --base-path /tmp/validator2 --chain /tmp/local-chain-spec-raw.json --scheme Sr25519 --suri "$$V2_SEED//im_online" --key-type imon; \
		./target/release/reef-node key insert --base-path /tmp/validator2 --chain /tmp/local-chain-spec-raw.json --scheme Sr25519 --suri "$$V2_SEED//authority_discovery" --key-type audi; \
		\
		echo "→ Validator 3"; \
		./target/release/reef-node key insert --base-path /tmp/validator3 --chain /tmp/local-chain-spec-raw.json --scheme Sr25519 --suri "$$V3_SEED//babe" --key-type babe; \
		./target/release/reef-node key insert --base-path /tmp/validator3 --chain /tmp/local-chain-spec-raw.json --scheme Ed25519 --suri "$$V3_SEED//grandpa" --key-type gran; \
		./target/release/reef-node key insert --base-path /tmp/validator3 --chain /tmp/local-chain-spec-raw.json --scheme Sr25519 --suri "$$V3_SEED//im_online" --key-type imon; \
		./target/release/reef-node key insert --base-path /tmp/validator3 --chain /tmp/local-chain-spec-raw.json --scheme Sr25519 --suri "$$V3_SEED//authority_discovery" --key-type audi; \
	'

	@echo "\n=========================================="
	@echo "Starting bootnode + validators (background)"
	@echo "=========================================="

	@bash -c '\
		BOOTNODE_PEER_ID=$$(./target/release/reef-node key inspect-node-key --file /tmp/bootnode_node_key.txt | awk "{print \$$NF}"); \
		BOOTNODE_ADDR="/ip4/127.0.0.1/tcp/30335/p2p/$$BOOTNODE_PEER_ID"; \
		echo "Bootnode PeerId = $$BOOTNODE_PEER_ID"; \
		\
		./target/release/reef-node --base-path /tmp/bootnode --chain /tmp/local-chain-spec-raw.json --port 30335 --listen-addr /ip4/0.0.0.0/tcp/30335
		--node-key-file /tmp/bootnode_node_key.txt --name Bootnode > /tmp/bootnode.log 2>&1 & \
		\
		./target/release/reef-node --base-path /tmp/validator1 --chain /tmp/local-chain-spec-raw.json --port 30333 --node-key-file /tmp/v1_node_key.txt --bootnodes $$BOOTNODE_ADDR --validator --rpc-external --rpc-cors all --rpc-methods Unsafe --name Validator1 > /tmp/validator1.log 2>&1 & \
		\
		./target/release/reef-node --base-path /tmp/validator2 --chain /tmp/local-chain-spec-raw.json --port 30334 --node-key-file /tmp/v2_node_key.txt --bootnodes $$BOOTNODE_ADDR --validator --rpc-external --rpc-cors all --rpc-methods Unsafe --name Validator2 > /tmp/validator2.log 2>&1 & \
		\
		./target/release/reef-node --base-path /tmp/validator3 --chain /tmp/local-chain-spec-raw.json --port 30336 --node-key-file /tmp/v3_node_key.txt --bootnodes $$BOOTNODE_ADDR --validator --rpc-external --rpc-cors all --rpc-methods Unsafe --name Validator3 > /tmp/validator3.log 2>&1 & \
		\
		echo ""; \
		echo "🚀 Network running!"; \
		echo "Bootnode:   $$BOOTNODE_ADDR"; \
		echo "Logs in /tmp/*.log"; \
		echo ""; \
		echo "📌 Container will now stay alive (tail -f /dev/null)"; \
		tail -F /tmp/bootnode.log /tmp/validator1.log /tmp/validator2.log /tmp/validator3.log \
	'
