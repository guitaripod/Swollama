import Foundation

/// ANSI escape codes used across the CLI for colored terminal output.
///
/// Every code resolves to an empty string when colors are disabled (see
/// ``OutputEnvironment/colorsEnabled``), so piped or `NO_COLOR` output stays clean automatically.
enum TerminalStyle {
    private static func code(_ value: String) -> String {
        OutputEnvironment.colorsEnabled ? value : ""
    }

    static var reset: String { code("\u{001B}[0m") }
    static var bold: String { code("\u{001B}[1m") }
    static var dim: String { code("\u{001B}[2m") }

    static var neonPink: String { code("\u{001B}[38;2;255;20;147m") }
    static var neonBlue: String { code("\u{001B}[38;2;0;255;255m") }
    static var neonGreen: String { code("\u{001B}[38;2;0;255;127m") }
    static var neonYellow: String { code("\u{001B}[38;2;255;215;0m") }
    static var mutedPurple: String { code("\u{001B}[38;2;147;112;219m") }

    static var bgDark: String { code("\u{001B}[48;2;25;25;35m") }
}
