# ---------------------------------------
# 1) Builder Stage
# ---------------------------------------
    FROM golang:1.20 as builder

    WORKDIR /go/src/github.com/gravitational/teleport
    
    # Install packages required for building Teleport, including Node.js & Yarn
    RUN apt-get update && apt-get install -y \
        make \
        git \
        ca-certificates \
        curl \
        nodejs \
        npm \
        && npm install -g yarn \
        && rm -rf /var/lib/apt/lists/*
    
    # Clone the desired Teleport release/tag (e.g. v13.3.1)
    RUN git clone --branch v13.3.1 --depth 1 https://github.com/gravitational/teleport.git .
    
    # Build Teleport (including web assets)
    RUN make full
    
    # ---------------------------------------
    # 2) Final Stage
    # ---------------------------------------
    FROM ubuntu:22.04
    
    RUN apt-get update && apt-get install -y ca-certificates && \
        rm -rf /var/lib/apt/lists/*
    
    WORKDIR /usr/local/bin
    
    COPY --from=builder /go/src/github.com/gravitational/teleport/build/teleport /usr/local/bin/teleport
    COPY --from=builder /go/src/github.com/gravitational/teleport/build/tctl /usr/local/bin/tctl
    COPY --from=builder /go/src/github.com/gravitational/teleport/build/tsh /usr/local/bin/tsh
    
    # Create Teleport data dir
    RUN mkdir -p /var/lib/teleport
    
    # Expose Teleport's default ports
    EXPOSE 3022 3023 3024 3025 3080 443
    
    ENTRYPOINT ["/usr/local/bin/teleport"]
    CMD ["start", "--roles=node,proxy,auth", "--config=/etc/teleport.yaml"]
    