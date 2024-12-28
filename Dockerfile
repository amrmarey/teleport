# ---------------------------------------
# 1) Builder Stage
# ---------------------------------------
    FROM golang:1.20 as builder

    WORKDIR /go/src/github.com/gravitational/teleport
    
    RUN apt-get update && apt-get install -y \
        make \
        git \
        ca-certificates && \
        rm -rf /var/lib/apt/lists/*
    
    # Clone Teleport source at v13.3.1
    RUN git clone --branch v13.3.1 --depth 1 https://github.com/gravitational/teleport.git .
    
    # Build Teleport (tsh, teleport, tctl)
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
    
    RUN mkdir -p /var/lib/teleport
    
    # Expose key Teleport ports:
    # - 443 for HTTPS (Proxy)
    # - 3022 for SSH
    # - 3025 for Teleport admin API (tctl)
    EXPOSE 443 3022 3023 3024 3025 3080
    
    ENTRYPOINT ["/usr/local/bin/teleport"]
    CMD ["start", "--roles=node,proxy,auth", "--config=/etc/teleport.yaml"]    