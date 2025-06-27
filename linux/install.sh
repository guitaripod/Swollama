#!/bin/bash
# Swollama Linux Installation Script
# Optimized for performance and security

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Installation directories
INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/swollama"

# Functions
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[*]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

check_dependencies() {
    print_status "Checking dependencies..."
    
    local deps=("swift" "curl" "systemctl")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_warning "Please install the missing dependencies and try again"
        exit 1
    fi
}

build_swollama() {
    print_status "Building Swollama with Linux optimizations..."
    
    # Build with release configuration for optimal performance
    swift build -c release \
        -Xswiftc -cross-module-optimization \
        -Xswiftc -whole-module-optimization \
        -Xswiftc -Osize \
        -Xlinker -z -Xlinker relro \
        -Xlinker -z -Xlinker now
    
    if [ $? -ne 0 ]; then
        print_error "Build failed"
        exit 1
    fi
}

install_binary() {
    print_status "Installing SwollamaCLI to $INSTALL_DIR..."
    
    # Find the built binary
    local binary_path=".build/release/SwollamaCLI"
    
    if [ ! -f "$binary_path" ]; then
        print_error "Binary not found at $binary_path"
        exit 1
    fi
    
    # Install with proper permissions
    install -m 755 "$binary_path" "$INSTALL_DIR/SwollamaCLI"
    
    # Create symlink for convenience
    ln -sf "$INSTALL_DIR/SwollamaCLI" "$INSTALL_DIR/swollama"
}

install_service() {
    print_status "Installing systemd service..."
    
    # Copy service file
    cp linux/swollama.service "$SERVICE_DIR/"
    
    # Reload systemd
    systemctl daemon-reload
}

create_config() {
    print_status "Creating configuration directory..."
    
    mkdir -p "$CONFIG_DIR"
    
    # Create default configuration
    cat > "$CONFIG_DIR/swollama.conf" <<EOF
# Swollama Configuration
# Default Ollama host
OLLAMA_HOST=http://localhost:11434

# Performance settings
SWOLLAMA_MAX_CONNECTIONS=10
SWOLLAMA_TIMEOUT=300
SWOLLAMA_RETRY_COUNT=3

# Logging
SWOLLAMA_LOG_LEVEL=info
EOF
    
    chmod 644 "$CONFIG_DIR/swollama.conf"
}

optimize_system() {
    print_status "Applying Linux system optimizations..."
    
    # Increase file descriptor limits for better performance
    if ! grep -q "swollama" /etc/security/limits.conf 2>/dev/null; then
        cat >> /etc/security/limits.conf <<EOF
# Swollama performance optimizations
* soft nofile 65536
* hard nofile 65536
EOF
    fi
    
    # TCP optimizations for better network performance
    if [ -f /etc/sysctl.conf ]; then
        if ! grep -q "swollama" /etc/sysctl.conf; then
            cat >> /etc/sysctl.conf <<EOF

# Swollama network optimizations
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
EOF
            sysctl -p
        fi
    fi
}

print_completion() {
    print_status "Installation completed successfully!"
    echo
    echo "Swollama has been installed to: $INSTALL_DIR/SwollamaCLI"
    echo "You can also use the 'swollama' command"
    echo
    echo "To start Swollama as a service:"
    echo "  systemctl start swollama@http://localhost:11434"
    echo
    echo "To enable Swollama at boot:"
    echo "  systemctl enable swollama@http://localhost:11434"
    echo
    echo "Configuration file: $CONFIG_DIR/swollama.conf"
}

# Main installation flow
main() {
    print_status "Starting Swollama Linux installation..."
    
    check_root
    check_dependencies
    build_swollama
    install_binary
    install_service
    create_config
    optimize_system
    print_completion
}

# Run main function
main "$@"