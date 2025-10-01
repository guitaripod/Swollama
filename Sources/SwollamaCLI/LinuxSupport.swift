






#if canImport(Glibc)
import Glibc
import Foundation


enum LinuxSupport {

    static func installSignalHandlers() {

        signal(SIGTERM, signalHandler)
        signal(SIGINT, signalHandler)
        signal(SIGPIPE, SIG_IGN)


        signal(SIGWINCH) { _ in

            CachedTerminalHelper.invalidateCache()
        }
    }


    static func configureMemorySettings() {

        #if os(Linux)

        let pageSize = sysconf(Int32(_SC_PAGESIZE))
        if pageSize > 0 {

            let bufferSize = 1024 * 1024
            let buffer = malloc(bufferSize)
            if let buffer = buffer {

                madvise(buffer, bufferSize, MADV_SEQUENTIAL)

                free(buffer)
            }
        }
        #endif
    }


    static func configureProcessPriority() {

        nice(-5)



    }


    private static let signalHandler: @convention(c) (Int32) -> Void = { signal in
        print("\nReceived signal \(signal), shutting down gracefully...")


        cleanupBeforeExit()


        exit(signal == SIGTERM ? 0 : 1)
    }


    private static func cleanupBeforeExit() {

        fflush(stdout)
        fflush(stderr)


        print("\u{1B}[?25h")
        print("\u{1B}[0m")
    }


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


private let MADV_SEQUENTIAL: Int32 = 2

#else


enum LinuxSupport {
    static func installSignalHandlers() {}
    static func configureMemorySettings() {}
    static func configureProcessPriority() {}
    static func getSystemInfo() -> String { return "System info not available" }
}

#endif