//
//  LinuxSupport.swift
//  SwollamaCLI
//
//  Linux-specific optimizations and features
//

#if canImport(Glibc)
import Glibc
import Foundation

/// Linux-specific system optimizations and signal handling
enum LinuxSupport {
    /// Install signal handlers for graceful shutdown
    static func installSignalHandlers() {
        // Handle SIGTERM and SIGINT for graceful shutdown
        signal(SIGTERM, signalHandler)
        signal(SIGINT, signalHandler)
        signal(SIGPIPE, SIG_IGN) // Ignore broken pipe errors
        
        // Handle terminal resize
        signal(SIGWINCH) { _ in
            // Clear terminal width cache on resize
            CachedTerminalHelper.invalidateCache()
        }
    }
    
    /// Configure memory optimization settings
    static func configureMemorySettings() {
        // Advise kernel about memory usage patterns
        #if os(Linux)
        // Use madvise for better memory performance
        let pageSize = sysconf(Int32(_SC_PAGESIZE))
        if pageSize > 0 {
            // Pre-allocate memory pages for better performance
            let bufferSize = 1024 * 1024 // 1MB
            let buffer = malloc(bufferSize)
            if let buffer = buffer {
                // Advise sequential access pattern
                madvise(buffer, bufferSize, MADV_SEQUENTIAL)
                // Free the temporary buffer
                free(buffer)
            }
        }
        #endif
    }
    
    /// Configure process priority for better performance
    static func configureProcessPriority() {
        // Set nice value for better scheduling
        nice(-5) // Slightly higher priority
        
        // Note: I/O priority setting requires syscall which is not available in Swift
        // Users can set it externally using ionice command
    }
    
    /// Signal handler for graceful shutdown
    private static let signalHandler: @convention(c) (Int32) -> Void = { signal in
        print("\nReceived signal \(signal), shutting down gracefully...")
        
        // Perform cleanup
        cleanupBeforeExit()
        
        // Exit with appropriate code
        exit(signal == SIGTERM ? 0 : 1)
    }
    
    /// Cleanup function called before exit
    private static func cleanupBeforeExit() {
        // Flush stdout to ensure all output is written
        fflush(stdout)
        fflush(stderr)
        
        // Reset terminal state if needed
        print("\u{1B}[?25h") // Show cursor
        print("\u{1B}[0m")    // Reset colors
    }
    
    /// Get system information for diagnostics
    static func getSystemInfo() -> String {
        var utsname = utsname()
        uname(&utsname)
        
        let sysname = withUnsafeBytes(of: &utsname.sysname) { bytes in
            String(cString: bytes.bindMemory(to: CChar.self).baseAddress!)
        }
        let release = withUnsafeBytes(of: &utsname.release) { bytes in
            String(cString: bytes.bindMemory(to: CChar.self).baseAddress!)
        }
        let machine = withUnsafeBytes(of: &utsname.machine) { bytes in
            String(cString: bytes.bindMemory(to: CChar.self).baseAddress!)
        }
        
        let memInfo = getMemoryInfo()
        
        return """
        System: \(sysname) \(release) (\(machine))
        Memory: \(memInfo.used)MB / \(memInfo.total)MB
        Processors: \(ProcessInfo.processInfo.processorCount)
        """
    }
    
    /// Get memory usage information
    private static func getMemoryInfo() -> (total: Int, used: Int) {
        let pageSize = sysconf(Int32(_SC_PAGESIZE))
        let totalPages = sysconf(Int32(_SC_PHYS_PAGES))
        let availablePages = sysconf(Int32(_SC_AVPHYS_PAGES))
        
        if pageSize > 0 && totalPages > 0 && availablePages > 0 {
            let totalMB = (totalPages * pageSize) / (1024 * 1024)
            let usedMB = ((totalPages - availablePages) * pageSize) / (1024 * 1024)
            return (Int(totalMB), Int(usedMB))
        }
        
        return (0, 0)
    }
}

// Memory advice constants
private let MADV_SEQUENTIAL: Int32 = 2

#else

// Stub implementation for non-Linux platforms
enum LinuxSupport {
    static func installSignalHandlers() {}
    static func configureMemorySettings() {}
    static func configureProcessPriority() {}
    static func getSystemInfo() -> String { return "System info not available" }
}

#endif