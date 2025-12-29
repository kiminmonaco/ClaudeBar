import Testing
@testable import Domain

@Suite("ClaudeAccountType Tests")
struct ClaudeAccountTypeTests {

    // MARK: - Display Name Tests

    @Test
    func `max account type has correct display name`() {
        #expect(ClaudeAccountType.max.displayName == "Claude Max")
    }

    @Test
    func `pro account type has correct display name`() {
        #expect(ClaudeAccountType.pro.displayName == "Claude Pro")
    }

    @Test
    func `api account type has correct display name`() {
        #expect(ClaudeAccountType.api.displayName == "API Usage")
    }

    // MARK: - Badge Text Tests

    @Test
    func `max account type has correct badge text`() {
        #expect(ClaudeAccountType.max.badgeText == "MAX")
    }

    @Test
    func `pro account type has correct badge text`() {
        #expect(ClaudeAccountType.pro.badgeText == "PRO")
    }

    @Test
    func `api account type has correct badge text`() {
        #expect(ClaudeAccountType.api.badgeText == "API")
    }

    // MARK: - Raw Value Tests

    @Test
    func `max account type has correct raw value`() {
        #expect(ClaudeAccountType.max.rawValue == "max")
    }

    @Test
    func `pro account type has correct raw value`() {
        #expect(ClaudeAccountType.pro.rawValue == "pro")
    }

    @Test
    func `api account type has correct raw value`() {
        #expect(ClaudeAccountType.api.rawValue == "api")
    }

    // MARK: - Initialization from Raw Value

    @Test
    func `can initialize max from raw value`() {
        #expect(ClaudeAccountType(rawValue: "max") == .max)
    }

    @Test
    func `can initialize pro from raw value`() {
        #expect(ClaudeAccountType(rawValue: "pro") == .pro)
    }

    @Test
    func `can initialize api from raw value`() {
        #expect(ClaudeAccountType(rawValue: "api") == .api)
    }

    @Test
    func `returns nil for unknown raw value`() {
        #expect(ClaudeAccountType(rawValue: "unknown") == nil)
    }

    // MARK: - Equality Tests

    @Test
    func `account types are equal when same`() {
        #expect(ClaudeAccountType.max == ClaudeAccountType.max)
        #expect(ClaudeAccountType.pro == ClaudeAccountType.pro)
        #expect(ClaudeAccountType.api == ClaudeAccountType.api)
    }

    @Test
    func `account types are not equal when different`() {
        #expect(ClaudeAccountType.max != ClaudeAccountType.pro)
        #expect(ClaudeAccountType.max != ClaudeAccountType.api)
        #expect(ClaudeAccountType.pro != ClaudeAccountType.api)
    }
}
