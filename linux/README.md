# Swollama for Linux

High-performance Ollama client optimized specifically for Linux systems.

## Performance Optimizations

### 1. **Network Streaming**
- Efficient chunk-based streaming with 64KB buffers
- Proper async/await implementation for Linux
- Zero-copy data transfer where possible
- Connection pooling and reuse

### 2. **Terminal Performance**
- Terminal width caching (1-second cache duration)
- Rate-limited progress updates (10 FPS max)
- Efficient terminal control sequences
- Smart progress threshold (0.1% minimum change)

### 3. **Memory Management**
- Pre-allocated buffers for streaming
- Memory advice hints to kernel (MADV_SEQUENTIAL)
- Optimized data structures
- Automatic memory cleanup on signals

### 4. **Build Optimizations**
- Cross-module optimization
- Whole-module optimization
- Size optimization (-Osize)
- Link-time optimization
- Security hardening (RELRO, NOW)

## Installation

### Quick Install
```bash
sudo ./linux/install.sh
```

### Manual Build
```bash
swift build -c release \
    -Xswiftc -cross-module-optimization \
    -Xswiftc -whole-module-optimization \
    -Xswiftc -Osize
```

### Docker
```bash
docker build -t swollama .
docker run --rm swollama list
```

## System Configuration

### 1. **File Descriptors**
Add to `/etc/security/limits.conf`:
```
* soft nofile 65536
* hard nofile 65536
```

### 2. **Network Optimization**
Add to `/etc/sysctl.conf`:
```
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
```

Apply with: `sudo sysctl -p`

### 3. **Systemd Service**
```bash
# Install service
sudo cp linux/swollama.service /etc/systemd/system/
sudo systemctl daemon-reload

# Start service
sudo systemctl start swollama@http://localhost:11434

# Enable at boot
sudo systemctl enable swollama@http://localhost:11434
```

## Linux-Specific Features

### Signal Handling
- **SIGTERM**: Graceful shutdown
- **SIGINT**: Clean exit (Ctrl+C)
- **SIGWINCH**: Terminal resize detection
- **SIGPIPE**: Ignored for network stability

### System Information
```bash
swollama --system-info
```
Displays:
- System details (kernel, architecture)
- Memory usage
- CPU information
- Performance settings

### Process Priority
- Automatically sets nice value (-5)
- I/O scheduling optimization
- CPU quota management

## Performance Tuning

### Environment Variables
```bash
# Optimize memory allocation
export GODEBUG=madvdontneed=1

# Set buffer sizes
export SWOLLAMA_BUFFER_SIZE=131072

# Connection pool size
export SWOLLAMA_MAX_CONNECTIONS=10
```

### Configuration File
Create `/etc/swollama/swollama.conf`:
```
OLLAMA_HOST=http://localhost:11434
SWOLLAMA_MAX_CONNECTIONS=10
SWOLLAMA_TIMEOUT=300
SWOLLAMA_RETRY_COUNT=3
SWOLLAMA_LOG_LEVEL=info
```

## Benchmarking

### Network Performance
```bash
# Test streaming performance
time swollama pull llama2

# Monitor network usage
iftop -i lo
```

### Memory Usage
```bash
# Monitor memory
smem -P swollama

# Detailed memory map
pmap -x $(pidof SwollamaCLI)
```

### CPU Profiling
```bash
# Profile CPU usage
perf record -g swollama generate llama2
perf report
```

## Troubleshooting

### Debug Mode
```bash
# Enable debug logging
export SWOLLAMA_LOG_LEVEL=debug
swollama list
```

### Common Issues

1. **Permission Denied**
   - Check file descriptors limit
   - Verify systemd service permissions

2. **Slow Performance**
   - Check network settings (sysctl)
   - Verify BBR congestion control is enabled
   - Monitor with `--system-info`

3. **Memory Issues**
   - Check available memory
   - Adjust GODEBUG settings
   - Monitor with `htop`

## Security

The systemd service includes comprehensive security hardening:
- NoNewPrivileges
- PrivateTmp
- ProtectSystem
- RestrictNamespaces
- SystemCallFilter
- Dynamic user creation

## Contributing

When contributing Linux-specific features:
1. Test on multiple distributions (Ubuntu, Fedora, Arch)
2. Use conditional compilation for Linux-only code
3. Document any kernel version requirements
4. Include performance benchmarks