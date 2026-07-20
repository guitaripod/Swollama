import Foundation

/// Writes a line to standard error, keeping standard output reserved for machine-consumable data.
func printToStderr(_ message: String = "") {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

/// Whether ANSI colors should be emitted.
///
/// Colors are suppressed when `NO_COLOR` is set (see https://no-color.org) or when standard output is
/// not an interactive terminal (e.g. when piped to a file or another program).
enum OutputEnvironment {
    static let colorsEnabled: Bool = {
        if ProcessInfo.processInfo.environment["NO_COLOR"] != nil { return false }
        return isatty(fileno(stdout)) != 0
    }()
}
