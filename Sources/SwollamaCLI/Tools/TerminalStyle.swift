import Foundation

/// ANSI escape codes used across the CLI for colored terminal output.
enum TerminalStyle {
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"

    static let neonPink = "\u{001B}[38;2;255;20;147m"
    static let neonBlue = "\u{001B}[38;2;0;255;255m"
    static let neonGreen = "\u{001B}[38;2;0;255;127m"
    static let neonYellow = "\u{001B}[38;2;255;215;0m"
    static let mutedPurple = "\u{001B}[38;2;147;112;219m"

    static let bgDark = "\u{001B}[48;2;25;25;35m"
}
