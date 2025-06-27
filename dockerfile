# High-performance Linux-optimized Dockerfile for Swollama
FROM swift:5.9-jammy as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy only package files first for better caching
COPY Package.swift ./

# Pre-fetch dependencies
RUN swift package resolve

# Copy source code (excluding tests)
COPY Sources/Swollama ./Sources/Swollama
COPY Sources/SwollamaCLI ./Sources/SwollamaCLI

# Build with maximum optimization for Linux
RUN swift build -c release \
    --product SwollamaCLI \
    -Xswiftc -cross-module-optimization \
    -Xswiftc -whole-module-optimization \
    -Xswiftc -Osize \
    -Xlinker -z -Xlinker relro \
    -Xlinker -z -Xlinker now \
    -Xlinker -s

# Runtime image - minimal size
FROM ubuntu:jammy

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4 \
    libxml2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Security: Create non-root user
RUN useradd -m -u 1001 -s /bin/bash swollama

# Copy binary from builder
COPY --from=builder /build/.build/release/SwollamaCLI /usr/local/bin/swollama

# Set up runtime environment
USER swollama
WORKDIR /home/swollama

# Performance: Pre-allocate shared memory for better networking
ENV GODEBUG=madvdontneed=1

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD swollama list || exit 1

ENTRYPOINT ["swollama"]
CMD ["--help"]