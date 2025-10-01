#if canImport(Darwin)
import Darwin
#else
import Glibc

let TIOCGWINSZ: UInt = 0x5413
#endif
import Foundation


protocol TerminalHelper {

    var terminalWidth: Int { get }
}


struct DefaultTerminalHelper: TerminalHelper {





    var terminalWidth: Int {
        var w = winsize()
        #if os(Linux)
        let result = ioctl(Int32(STDOUT_FILENO), UInt(TIOCGWINSZ), &w)
        #else
        let result = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
        #endif

        guard result == 0 else {
            return 50
        }
        return Int(w.ws_col)
    }
}
