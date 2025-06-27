# SwollamaCLI Remastered

A completely remastered command-line interface for Ollama with enhanced safety, convenience, and streaming support.

## 🚀 Key Improvements

### 1. **Enhanced Chat Interface**
- **Rich Terminal UI**: Cyberpunk-themed colorful interface with ANSI escape codes
- **Advanced Commands**: Save/load conversations, switch models mid-chat, undo/retry messages
- **Token Tracking**: Real-time token counting with context window warnings
- **Multi-line Input**: Support for complex prompts with triple-backtick termination
- **Command History**: Navigate through previous commands with arrow keys
- **Auto-completion**: Smart command and model name completion

### 2. **Fixed Streaming**
- **Proper Async Implementation**: Uses `AsyncThrowingStream` with correct buffering
- **Platform Optimizations**: 64KB buffer size for Linux, native streaming for macOS
- **Real-time Display**: Immediate output with `fflush(stdout)` after each chunk
- **Stream Monitoring**: Debug mode to track chunk delivery and performance

### 3. **Robust Error Handling**
- **Automatic Recovery**: Smart retry strategies based on error type
- **Fallback Models**: Automatically switch to alternative models on failure
- **Connection Monitoring**: Health checks with automatic reconnection
- **Graceful Degradation**: Continue conversation even with partial failures
- **User-friendly Messages**: Clear error descriptions with suggested fixes

### 4. **Safety Features**
- **Signal Handling**: Graceful shutdown on SIGTERM/SIGINT
- **Resource Cleanup**: Automatic terminal reset and cursor restoration
- **Connection Validation**: Pre-flight checks before executing commands
- **Memory Management**: Optimized for long-running sessions
- **Secure Input**: Password input mode for sensitive data

### 5. **Convenience Features**
- **Command Shortcuts**: Use `c` for chat, `ls` for list, etc.
- **Environment Variables**: `OLLAMA_HOST` for default server configuration
- **Configuration Options**: `--no-timestamps`, `--no-tokens`, `--markdown`
- **Auto-save**: Optionally save conversations automatically on exit
- **Flexible Model Names**: Support for namespace/name:tag format

## 📋 Usage Examples

### Basic Chat
```bash
swollama chat llama2
```

### Advanced Chat Options
```bash
# Chat without timestamps
swollama chat codellama --no-timestamps

# Auto-save conversation
swollama chat mistral --auto-save conversation.json

# Use remote Ollama instance
swollama --host http://remote:11434 chat llama2
```

### Chat Commands
- `/help` - Show available commands
- `/save [filename]` - Save current conversation
- `/load [filename]` - Load previous conversation
- `/model <name>` - Switch to different model
- `/retry` - Retry last assistant response
- `/undo` - Remove last exchange
- `/tokens` - Toggle token count display
- `/system <message>` - Update system message
- `/clear` - Clear conversation history
- `/exit` or `/quit` - End chat session

## 🔧 Technical Details

### Streaming Architecture
The remastered CLI properly handles streaming by:
1. Creating an `AsyncThrowingStream` for chat/generation endpoints
2. Processing newline-delimited JSON chunks in real-time
3. Buffering incomplete chunks until a complete JSON object is received
4. Flushing output immediately for responsive user experience

### Error Recovery System
- **Network Errors**: Retry with exponential backoff
- **Model Not Found**: Suggest fallback to default model
- **Server Errors**: Retry with longer delays
- **Service Unavailable**: Extended retry attempts
- **Connection Lost**: Automatic reconnection attempts

### Performance Optimizations
- **Large Buffer Size**: 64KB for optimal throughput
- **Connection Pooling**: Reuse HTTP connections
- **Memory Optimization**: Sequential access patterns with madvise
- **Minimal Latency**: Direct stdout flushing for immediate feedback

## 🛡️ Safety Guarantees

1. **No Data Loss**: Conversations can be saved/loaded at any time
2. **Clean Exit**: Always resets terminal state on exit
3. **Error Recovery**: Automatic retry and fallback mechanisms
4. **Resource Management**: Proper cleanup of network connections
5. **Signal Safety**: Handles interrupts gracefully

## 🎯 Future Enhancements

While the core remastering is complete, these features could be added:
- Markdown rendering for formatted responses
- Plugin system for custom commands
- Response caching for repeated queries
- Batch processing mode
- Voice input/output support

The remastered SwollamaCLI provides a production-ready, user-friendly interface for interacting with Ollama models, with robust error handling and a delightful user experience.