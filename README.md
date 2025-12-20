# ClaudeBar

[![Build](https://github.com/tddworks/ClaudeBar/actions/workflows/build.yml/badge.svg)](https://github.com/tddworks/ClaudeBar/actions/workflows/build.yml)
[![Tests](https://github.com/tddworks/ClaudeBar/actions/workflows/tests.yml/badge.svg)](https://github.com/tddworks/ClaudeBar/actions/workflows/tests.yml)
[![codecov](https://codecov.io/gh/tddworks/ClaudeBar/graph/badge.svg)](https://codecov.io/gh/tddworks/ClaudeBar)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2015-blue.svg)](https://developer.apple.com)

A macOS menu bar application that monitors AI coding assistant usage quotas (Claude, Codex, Gemini). It probes CLI tools to fetch quota information and displays it in a menu bar interface with system notifications for status changes.

## Features

- Monitor usage quotas for multiple AI providers (Claude, Codex, Gemini)
- Menu bar interface for quick access
- System notifications for quota status changes
- Auto-refresh at configurable intervals

## Requirements

- macOS 15+
- Swift 6.2+

## Installation

```bash
git clone https://github.com/tddworks/ClaudeBar.git
cd ClaudeBar
swift build -c release
```

## Usage

```bash
swift run ClaudeBar
```

## Development

```bash
# Build the project
swift build

# Run all tests
swift test

# Run a specific test
swift test --filter "QuotaMonitorTests"
```

## Architecture

The project follows clean architecture with hexagonal/ports-and-adapters patterns:

- **Domain**: Pure business logic with no external dependencies
- **Infrastructure**: Technical implementations (CLI probes, notifications)
- **App**: SwiftUI menu bar application

## License

MIT
