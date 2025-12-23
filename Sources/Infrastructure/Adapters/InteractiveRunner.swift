import Darwin
import Foundation

/// Runs CLI commands interactively, simulating a real terminal session.
/// Answers the user question: "Run this command and get the output."
public struct InteractiveRunner: Sendable {
    public struct Result: Sendable {
        public let output: String
        public let exitCode: Int32
    }

    public struct Options: Sendable {
        public var timeout: TimeInterval
        public var workingDirectory: URL?
        public var arguments: [String]
        public var autoResponses: [String: String]

        public init(
            timeout: TimeInterval = 20.0,
            workingDirectory: URL? = nil,
            arguments: [String] = [],
            autoResponses: [String: String] = [:]
        ) {
            self.timeout = timeout
            self.workingDirectory = workingDirectory
            self.arguments = arguments
            self.autoResponses = autoResponses
        }
    }

    public enum RunError: Error, LocalizedError, Sendable {
        case binaryNotFound(String)
        case launchFailed(String)
        case timedOut

        public var errorDescription: String? {
            switch self {
            case let .binaryNotFound(bin):
                "CLI '\(bin)' not found. Please install it and ensure it's on PATH."
            case let .launchFailed(msg):
                "Failed to launch process: \(msg)"
            case .timedOut:
                "Command timed out."
            }
        }
    }

    private static let terminalRows: UInt16 = 50
    private static let terminalCols: UInt16 = 160

    public init() {}

    /// Runs a command interactively and returns the captured output.
    public func run(
        binary: String,
        input: String,
        options: Options = Options()
    ) throws -> Result {
        let resolved = try resolveBinary(binary)
        let (primaryFD, secondaryFD) = try createPTY()

        _ = fcntl(primaryFD, F_SETFL, O_NONBLOCK)

        let primaryHandle = FileHandle(fileDescriptor: primaryFD, closeOnDealloc: true)
        let secondaryHandle = FileHandle(fileDescriptor: secondaryFD, closeOnDealloc: true)

        let proc = configureProcess(
            executablePath: resolved,
            options: options,
            ptyHandle: secondaryHandle
        )

        var cleanedUp = false
        var didLaunch = false

        func cleanup() {
            guard !cleanedUp else { return }
            cleanedUp = true

            try? primaryHandle.close()
            try? secondaryHandle.close()

            if didLaunch, proc.isRunning {
                proc.terminate()
                let waitDeadline = Date().addingTimeInterval(2.0)
                while proc.isRunning, Date() < waitDeadline {
                    usleep(100_000)
                }
                if proc.isRunning {
                    kill(proc.processIdentifier, SIGKILL)
                }
                proc.waitUntilExit()
            }
        }

        defer { cleanup() }

        try proc.run()
        didLaunch = true

        // Initial delay for process startup
        usleep(400_000)

        // Send initial input
        try sendInput(input, to: primaryHandle)

        // Read loop with auto-responses
        let buffer = try readWithAutoResponses(
            from: primaryFD,
            handle: primaryHandle,
            process: proc,
            options: options
        )

        guard let text = String(data: buffer, encoding: .utf8), !text.isEmpty else {
            throw RunError.timedOut
        }

        let exitCode: Int32 = proc.isRunning ? -1 : proc.terminationStatus
        return Result(output: text, exitCode: exitCode)
    }

    // MARK: - Private Helpers

    private func resolveBinary(_ binary: String) throws -> String {
        if FileManager.default.isExecutableFile(atPath: binary) {
            return binary
        }
        if let found = BinaryLocator.which(binary) {
            return found
        }
        throw RunError.binaryNotFound(binary)
    }

    private func createPTY() throws -> (primary: Int32, secondary: Int32) {
        var primaryFD: Int32 = -1
        var secondaryFD: Int32 = -1
        var win = winsize(
            ws_row: Self.terminalRows,
            ws_col: Self.terminalCols,
            ws_xpixel: 0,
            ws_ypixel: 0
        )
        guard openpty(&primaryFD, &secondaryFD, nil, nil, &win) == 0 else {
            throw RunError.launchFailed("openpty failed")
        }
        return (primaryFD, secondaryFD)
    }

    private func configureProcess(
        executablePath: String,
        options: Options,
        ptyHandle: FileHandle
    ) -> Process {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: executablePath)
        proc.arguments = options.arguments
        proc.standardInput = ptyHandle
        proc.standardOutput = ptyHandle
        proc.standardError = ptyHandle
        proc.environment = Self.enrichedEnvironment()

        if let workingDirectory = options.workingDirectory {
            proc.currentDirectoryURL = workingDirectory
        }

        return proc
    }

    private func sendInput(_ input: String, to handle: FileHandle) throws {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let data = (trimmed + "\r").data(using: .utf8) else { return }
        try handle.write(contentsOf: data)
    }

    private func readWithAutoResponses(
        from fd: Int32,
        handle: FileHandle,
        process: Process,
        options: Options
    ) throws -> Data {
        let deadline = Date().addingTimeInterval(options.timeout)
        var buffer = Data()

        let autoResponseNeedles = options.autoResponses.map {
            (needle: Data($0.key.utf8), response: Data($0.value.utf8))
        }
        var triggeredResponses = Set<Data>()

        while Date() < deadline {
            readAvailableData(from: fd, into: &buffer)

            // Check for prompts that need auto-responses
            for item in autoResponseNeedles where !triggeredResponses.contains(item.needle) {
                if buffer.range(of: item.needle) != nil {
                    try? handle.write(contentsOf: item.response)
                    triggeredResponses.insert(item.needle)
                }
            }

            if !process.isRunning { break }
            usleep(60000)
        }

        // Final read to capture remaining output
        readAvailableData(from: fd, into: &buffer)
        return buffer
    }

    private func readAvailableData(from fd: Int32, into buffer: inout Data) {
        var tmp = [UInt8](repeating: 0, count: 8192)
        while true {
            let n = Darwin.read(fd, &tmp, tmp.count)
            if n > 0 {
                buffer.append(contentsOf: tmp.prefix(n))
            } else {
                break
            }
        }
    }

    private static func enrichedEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = BinaryLocator.effectivePATH()
        env["HOME"] = env["HOME"] ?? NSHomeDirectory()
        env["TERM"] = env["TERM"] ?? "xterm-256color"
        env["COLORTERM"] = env["COLORTERM"] ?? "truecolor"
        env["LANG"] = env["LANG"] ?? "en_US.UTF-8"
        env["CI"] = env["CI"] ?? "0"
        return env
    }
}