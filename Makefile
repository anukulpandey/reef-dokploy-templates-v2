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
	@echo "Setting up local validator network..."
	@echo "=========================================="
	@# Clean up previous chain data
	@echo "\n[2/7] Cleaning up previous chain data..."
	@rm -rf /tmp/validator1 /tmp/validator2 /tmp/validator3 /tmp/bootnode /tmp/validator1.txt /tmp/validator2.txt /tmp/validator3.txt /tmp/v1_seed.txt /tmp/v2_seed.txt /tmp/v3_seed.txt /tmp/v1_addr.txt /tmp/v2_addr.txt /tmp/v3_addr.txt /tmp/bootnode_peer_id.txt /tmp/bootnode_node_key.txt /tmp/v1_node_key.txt /tmp/v2_node_key.txt /tmp/v3_node_key.txt /tmp/local-chain-spec.json /tmp/local-chain-spec-updated.json /tmp/local-chain-spec-raw.json
	@# Generate new accounts and update chain spec
	@echo "\n[3/7] Generating new validator accounts..."
	@./target/release/reef-node key generate --scheme Sr25519 --output-type json > /tmp/validator1.txt
	@./target/release/reef-node key generate --scheme Sr25519 --output-type json > /tmp/validator2.txt
	@./target/release/reef-node key generate --scheme Sr25519 --output-type json > /tmp/validator3.txt
	@# Generate random node keys
	@echo "\n[4/7] Generating random node keys..."
	@./target/release/reef-node key generate-node-key --chain local > /tmp/bootnode_node_key.txt
	@./target/release/reef-node key generate-node-key --chain local > /tmp/v1_node_key.txt
	@./target/release/reef-node key generate-node-key --chain local > /tmp/v2_node_key.txt
	@./target/release/reef-node key generate-node-key --chain local > /tmp/v3_node_key.txt
	@echo "\n[5/7] Downloading pre-generated RAW chain spec..."
	@wget -q -O /tmp/local-chain-spec-raw.json http://reef.host:8000/local-chain-spec-raw.json
	@echo "✅ Downloaded /tmp/local-chain-spec-raw.json"

	@# Insert keys for Validator 1
	@echo "\n[6/9] Inserting keys for Validator 1..."
	@bash -c ' \
		V1_SEED=$$(cat /tmp/v1_seed.txt); \
		./target/release/reef-node key insert --base-path /tmp/validator1 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Sr25519 \
			--suri "$$V1_SEED//babe" \
			--key-type babe; \
		./target/release/reef-node key insert --base-path /tmp/validator1 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Ed25519 \
			--suri "$$V1_SEED//grandpa" \
			--key-type gran; \
		./target/release/reef-node key insert --base-path /tmp/validator1 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Sr25519 \
			--suri "$$V1_SEED//im_online" \
			--key-type imon; \
		./target/release/reef-node key insert --base-path /tmp/validator1 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Sr25519 \
			--suri "$$V1_SEED//authority_discovery" \
			--key-type audi \
	'
	@# Insert keys for Validator 2
	@echo "\n[7/9] Inserting keys for Validator 2..."
	@bash -c ' \
		V2_SEED=$$(cat /tmp/v2_seed.txt); \
		./target/release/reef-node key insert --base-path /tmp/validator2 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Sr25519 \
			--suri "$$V2_SEED//babe" \
			--key-type babe; \
		./target/release/reef-node key insert --base-path /tmp/validator2 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Ed25519 \
			--suri "$$V2_SEED//grandpa" \
			--key-type gran; \
		./target/release/reef-node key insert --base-path /tmp/validator2 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Sr25519 \
			--suri "$$V2_SEED//im_online" \
			--key-type imon; \
		./target/release/reef-node key insert --base-path /tmp/validator2 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Sr25519 \
			--suri "$$V2_SEED//authority_discovery" \
			--key-type audi \
	'
	@# Insert keys for Validator 3
	@echo "\n[8/9] Inserting keys for Validator 3..."
	@bash -c ' \
		V3_SEED=$$(cat /tmp/v3_seed.txt); \
		./target/release/reef-node key insert --base-path /tmp/validator3 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Sr25519 \
			--suri "$$V3_SEED//babe" \
			--key-type babe; \
		./target/release/reef-node key insert --base-path /tmp/validator3 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Ed25519 \
			--suri "$$V3_SEED//grandpa" \
			--key-type gran; \
		./target/release/reef-node key insert --base-path /tmp/validator3 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Sr25519 \
			--suri "$$V3_SEED//im_online" \
			--key-type imon; \
		./target/release/reef-node key insert --base-path /tmp/validator3 \
			--chain=/tmp/local-chain-spec-raw.json \
			--scheme Sr25519 \
			--suri "$$V3_SEED//authority_discovery" \
			--key-type audi \
	'
	@# Start the validator nodes
	@echo "\n[9/9] Starting bootnode and validator nodes..."
	@bash -c ' \
		V1_ADDR=$$(cat /tmp/v1_addr.txt); \
		V2_ADDR=$$(cat /tmp/v2_addr.txt); \
		V3_ADDR=$$(cat /tmp/v3_addr.txt); \
		BOOTNODE_NODE_KEY=$$(cat /tmp/bootnode_node_key.txt); \
		BOOTNODE_PEER_ID=$$(./target/release/reef-node key inspect-node-key --file /tmp/bootnode_node_key.txt 2>/dev/null | tail -n1); \
		echo "$$BOOTNODE_PEER_ID" > /tmp/bootnode_peer_id.txt; \
		echo ""; \
		echo "Bootnode will run on:"; \
		echo "  - P2P port: 30335"; \
		echo "  - Peer ID: $$BOOTNODE_PEER_ID"; \
		echo ""; \
		echo "Validator 1 ($$V1_ADDR) will run on:"; \
		echo "  - P2P port: 30333"; \
		echo "  - RPC port: 9944"; \
		echo "  - WebSocket: ws://127.0.0.1:9944"; \
		echo ""; \
		echo "Validator 2 ($$V2_ADDR) will run on:"; \
		echo "  - P2P port: 30334"; \
		echo "  - RPC port: 9945"; \
		echo "  - WebSocket: ws://127.0.0.1:9945"; \
		echo ""; \
		echo "Validator 3 ($$V3_ADDR) will run on:"; \
		echo "  - P2P port: 30336"; \
		echo "  - RPC port: 9946"; \
		echo "  - WebSocket: ws://127.0.0.1:9946" \
	'
		@echo "\n=========================================="
	@echo "Starting bootnode + validators (background)..."
	@echo "Press Ctrl+C to stop all nodes"
	@echo "=========================================="

	@# Start Bootnode
	@./target/release/reef-node \
		--base-path /tmp/bootnode \
		--chain /tmp/local-chain-spec-raw.json \
		--port 30335 \
		--node-key-file /tmp/bootnode_node_key.txt \
		--name Bootnode \
		> /tmp/bootnode.log 2>&1 & \
	BOOT_PID=$$!; \
	sleep 3; \
	\
	BOOTNODE_PEER_ID=$$(./target/release/reef-node key inspect-node-key \
		--file /tmp/bootnode_node_key.txt | awk '{print $$NF}'); \
	echo "$$BOOTNODE_PEER_ID" > /tmp/bootnode_peer_id.txt; \
	echo "✅ Bootnode peer id: $$BOOTNODE_PEER_ID"; \
	BOOTNODE_ADDR="/ip4/127.0.0.1/tcp/30335/p2p/$$BOOTNODE_PEER_ID"; \
	\
	echo "🚀 Starting validators..."; \
	\
	./target/release/reef-node \
		--base-path /tmp/validator1 \
		--chain /tmp/local-chain-spec-raw.json \
		--port 30333 \
		--rpc-port 9944 \
		--node-key-file /tmp/v1_node_key.txt \
		--bootnodes $$BOOTNODE_ADDR \
		--validator \
		--rpc-external --rpc-cors all --rpc-methods Unsafe \
		--name Validator1 \
		> /tmp/validator1.log 2>&1 & \
	V1_PID=$$!; \
	\
	./target/release/reef-node \
		--base-path /tmp/validator2 \
		--chain /tmp/local-chain-spec-raw.json \
		--port 30334 \
		--rpc-port 9945 \
		--node-key-file /tmp/v2_node_key.txt \
		--bootnodes $$BOOTNODE_ADDR \
		--validator \
		--rpc-external --rpc-cors all --rpc-methods Unsafe \
		--name Validator2 \
		> /tmp/validator2.log 2>&1 & \
	V2_PID=$$!; \
	\
	./target/release/reef-node \
		--base-path /tmp/validator3 \
		--chain /tmp/local-chain-spec-raw.json \
		--port 30336 \
		--rpc-port 9946 \
		--node-key-file /tmp/v3_node_key.txt \
		--bootnodes $$BOOTNODE_ADDR \
		--validator \
		--rpc-external --rpc-cors all --rpc-methods Unsafe \
		--name Validator3 \
		> /tmp/validator3.log 2>&1 & \
	V3_PID=$$!; \
	\
	echo ""; \
	echo "✅ Local validator network started!"; \
	echo "Bootnode:   p2p://$$BOOTNODE_PEER_ID@127.0.0.1:30335"; \
	echo "Validator1 ws://127.0.0.1:9944"; \
	echo "Validator2 ws://127.0.0.1:9945"; \
	echo "Validator3 ws://127.0.0.1:9946"; \
	echo ""; \
	echo "📄 Logs:"; \
	echo "  /tmp/bootnode.log"; \
	echo "  /tmp/validator1.log"; \
	echo "  /tmp/validator2.log"; \
	echo "  /tmp/validator3.log"; \
	echo ""; \
	\
	wait $$BOOT_PID $$V1_PID $$V2_PID $$V3_PID
	'
