import Foundation

/// Locates CLI binaries on the system.
/// Answers the user question: "Is this tool available?"
public struct BinaryLocator: Sendable {
    public init() {}

    /// Finds a binary by name, searching common installation paths.
    /// Returns the full path if found, nil otherwise.
    public func locate(_ tool: String) -> String? {
        Self.which(tool)
    }

    /// Static convenience for locating binaries.
    public static func which(_ tool: String) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        proc.arguments = [tool]
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = effectivePATH()
        proc.environment = env
        let pipe = Pipe()
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let path = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !path.isEmpty else { return nil }
        return path
    }

    /// Returns PATH enriched with common CLI installation locations.
    public static func effectivePATH() -> String {
        let home = NSHomeDirectory()
        let common = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "\(home)/.local/bin",
            "\(home)/.bun/bin",
            "\(home)/.nvm/versions/node/*/bin",
            "/usr/bin",
            "/bin",
        ]
        let existing = ProcessInfo.processInfo.environment["PATH"] ?? ""
        return (common + [existing]).joined(separator: ":")
    }
}