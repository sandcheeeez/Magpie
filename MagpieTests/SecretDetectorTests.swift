//
//  SecretDetectorTests.swift
//  MagpieTests
//

import Testing
import AppKit
import SwiftData
@testable import Magpie

/// Sample secrets are made up and assembled at runtime, so secret scanners don't flag this file.
@Suite struct SecretDetectorTests {

    private static func token(_ prefix: String, _ length: Int, from alphabet: String = "aB3cD4eF5gH6jK7mN8pQ9rS2tU") -> String {
        let chars = Array(alphabet)
        return prefix + String((0..<length).map({ chars[$0 % chars.count] }))
    }

    static let certain: [(String, String)] = [
        (token("ghp" + "_", 36), "GitHub token"),
        (token("github" + "_pat_", 70), "GitHub token"),
        ("AKIA" + "IOSFODNN7EXAMPLE", "AWS access key"),
        (token("sk" + "_live_", 24), "Stripe key"),
        (token("sk" + "-ant-api03-", 40), "Anthropic API key"),
        (token("sk" + "-proj-", 48), "OpenAI API key"),
        (token("AI" + "za", 35), "Google API key"),
        (token("xox" + "b-", 30), "Slack token"),
        ("-----BEGIN OPENSSH " + "PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAA\n-----END OPENSSH PRIVATE KEY-----", "Private key"),
        ("eyJ" + "hbGciOiJIUzI1NiJ9.eyJ" + "zdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U", "JSON Web Token"),
        ("postgres://admin:" + "hunter22@db.example.com:5432/app", "Password in a link"),
        ("export GH_TOKEN=" + token("ghp" + "_", 36), "GitHub token"),
    ]

    @Test(arguments: certain)
    func knownFormatsAreCertain(text: String, reason: String) throws {
        let finding = try #require(SecretDetector.detect(in: text))
        #expect(finding.reason == reason)
        #expect(finding.isCertain)
    }

    @Test(arguments: ["Tr0ub4dor&3x", "p@55W0rd!Zq", token("", 32, from: "x7Kq2mPz9RtL4vWn8YcB3sDf6HjA1uEo"),
                      "password: correcthorsebattery", "api_key = \"abcd1234efgh\"", "The wifi password is BlueFalcon42"])
    func possibleSecretsAreGuesses(text: String) throws {
        let finding = try #require(SecretDetector.detect(in: text))
        #expect(!finding.isCertain)
    }

    @Test(arguments: [
        "Meeting notes: ship the redesign, then pinning.", "https://github.com/sandcheeeez/Magpie", "https://example.com:8080/path?q=1",
        "3F2504E0-4F89-11D3-9A0C-0305E82C3301", "8fd3198a1c2b3d4e5f60718293a4b5c6d7e8f901", "v1.2.3-beta.4", "2026-11-07",
        "/Users/me/Documents/Report.pdf", "hello@example.com", "getUserName", "my-feature-branch", "#FF6B35", "+1 (555) 201-8841",
        "func greet(_ name: String) -> String {\n    return \"Hello\"\n}", "Reset your password from the account page.",
    ])
    func ordinaryTextIsNotASecret(text: String) {
        #expect(SecretDetector.detect(in: text) == nil)
    }

    @Test func maskHidesMostOfTheText() {
        let masked = SecretDetector.mask(Self.token("ghp" + "_", 36))
        #expect(masked.hasPrefix("ghp_"))
        #expect(masked.contains("•"))
        #expect(masked.count < 20)
        #expect(SecretDetector.mask("hunter2") == "••••••••")
    }

    @Test func analysisRecordsSecrets() {
        #expect(ClipAnalyzer.analyze([.string: Data(Self.certain[0].0.utf8)]).secret?.isCertain == true)
        #expect(ClipAnalyzer.analyze([.string: Data("hello there".utf8)]).secret == nil)
    }
}

/// How the history suggests and deletes secrets.
@Suite struct HistorySecretTests {

    let history: History

    init() throws {
        history = History(container: try HistoryStore.makeContainer(inMemory: true), maxItems: 100, persistsSettings: false)
    }

    private func insert(_ string: String, copiedAt: Date = Date()) -> HistoryItem {
        return history.insert(data: [.string: Data(string.utf8)], copiedAt: copiedAt, sourceBundleId: nil)
    }

    private let gitHubToken = "ghp" + "_" + "x7Kq2mPz9RtL4vWn8YcB3sDf6HjA1uEo5iGk"

    @Test func certainSecretsAreSuggested() {
        let secret = insert(gitHubToken)
        _ = insert("hello")
        #expect(history.suggestedSecrets == [secret])
    }

    @Test func keptAndPinnedSecretsAreNotSuggested() {
        let kept = insert(gitHubToken)
        history.setSecretDismissed(true, for: kept)
        _ = insert("AKIA" + "IOSFODNN7EXAMPLE")
        history.setPinned(true, forItemAt: 0)
        #expect(history.suggestedSecrets.isEmpty)
    }

    @Test func theModelsVerdictDecidesGuesses() {
        let guess = insert("Tr0ub4dor&3x")
        #expect(guess.needsSecretReview)
        history.setSecretVerdict(false, for: guess)
        #expect(!guess.isSuggestedSecret)
        history.setSecretVerdict(true, for: guess)
        #expect(guess.isSuggestedSecret)
        #expect(!guess.needsSecretReview)
    }

    @Test func automaticDeletionOnlyRemovesOldConfirmedSecrets() {
        let old = insert(gitHubToken, copiedAt: Date().addingTimeInterval(-7200))
        let oldGuess = insert("Tr0ub4dor&3x", copiedAt: Date().addingTimeInterval(-7200))
        let oldKept = insert("AKIA" + "IOSFODNN7EXAMPLE", copiedAt: Date().addingTimeInterval(-7200))
        history.setSecretDismissed(true, for: oldKept)
        let recent = insert("sk" + "_live_" + "aB3cD4eF5gH6jK7mN8pQ9rS2")

        history.deleteSecrets(copiedBefore: Date().addingTimeInterval(-3600))

        #expect(!history.items.contains(old))
        #expect(history.items.contains(oldGuess))
        #expect(history.items.contains(oldKept))
        #expect(history.items.contains(recent))
    }

    @Test func dismissalSurvivesReloading() throws {
        let container = try HistoryStore.makeContainer(inMemory: true)
        let first = History(container: container, maxItems: 100, persistsSettings: false)
        let item = first.insert(data: [.string: Data(gitHubToken.utf8)], sourceBundleId: nil)
        first.setSecretDismissed(true, for: item)

        let reloaded = History(container: container, maxItems: 100, persistsSettings: false)
        #expect(reloaded.items.first?.secretDismissed == true)
        #expect(reloaded.suggestedSecrets.isEmpty)
    }
}
