FROM ubuntu:22.04

# Install required tools
RUN apt-get update && apt-get install -y \
    curl ca-certificates gnupg lsb-release && \
    apt-get clean

# Copy reef-node from your node image
COPY --from=anukulpandey/reef-chain-node /usr/local/bin/reef-node /usr/local/bin/reef-node

# Copy scripts
WORKDIR /workspace
COPY scripts/update-spec.sh /workspace/update-spec.sh
COPY scripts/run.sh /workspace/run.sh

RUN chmod +x /workspace/update-spec.sh /workspace/run.sh

CMD ["/workspace/run.sh"]
