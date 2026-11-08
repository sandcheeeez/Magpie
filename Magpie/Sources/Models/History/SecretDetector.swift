//
//  SecretDetector.swift
//  Magpie
//

import Foundation

/// A sign that an item holds a password, token or key.
struct SecretFinding: Equatable {
    /// What it looks like, e.g. "GitHub token".
    var reason: String
    /// Known formats, such as a GitHub token or a private key, are certain. Text that only looks random, or mentions a password, is possible, and the on-device model is asked about it (`SecretReviewer`).
    var isCertain: Bool
}

/// Finds passwords, API keys and tokens in copied text, so Magpie can suggest deleting them. Runs entirely on-device.
enum SecretDetector {

    /// Formats used by specific services. Patterns must avoid nested quantifiers (see `ClipAnalyzer`).
    private static let knownFormats: [(String, Regex<AnyRegexOutput>)] = [
        ("Private key", try! Regex(#"-----BEGIN [A-Z ]{0,24}PRIVATE KEY( BLOCK)?-----"#)),
        ("Age secret key", try! Regex(#"AGE-SECRET-KEY-1[0-9A-Z]{58}"#)),
        ("AWS access key", try! Regex(#"\b(AKIA|ASIA)[0-9A-Z]{16}\b"#)),
        ("GitHub token", try! Regex(#"\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}\b"#)),
        ("GitHub token", try! Regex(#"\bgithub_pat_[A-Za-z0-9_]{60,}"#)),
        ("GitLab token", try! Regex(#"\bglpat-[A-Za-z0-9_-]{20,}"#)),
        ("Slack token", try! Regex(#"\bxox[abposr]-[A-Za-z0-9-]{10,}"#)),
        ("Slack webhook", try! Regex(#"hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+"#)),
        ("Stripe key", try! Regex(#"\b(sk|rk)_(live|test)_[A-Za-z0-9]{16,}"#)),
        ("Anthropic API key", try! Regex(#"\bsk-ant-[A-Za-z0-9_-]{20,}"#)),
        ("OpenAI API key", try! Regex(#"\bsk-(proj-|svcacct-)?[A-Za-z0-9_-]{32,}"#)),
        ("Google API key", try! Regex(#"\bAIza[0-9A-Za-z_-]{35}\b"#)),
        ("Hugging Face token", try! Regex(#"\bhf_[A-Za-z0-9]{30,}\b"#)),
        ("npm token", try! Regex(#"\bnpm_[A-Za-z0-9]{36}\b"#)),
        ("PyPI token", try! Regex(#"\bpypi-[A-Za-z0-9_-]{50,}"#)),
        ("DigitalOcean token", try! Regex(#"\bdo[por]_v1_[a-f0-9]{64}\b"#)),
        ("Tailscale key", try! Regex(#"\btskey-[a-z]+-[A-Za-z0-9-]{10,}"#)),
        ("SendGrid key", try! Regex(#"\bSG\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}"#)),
        ("Shopify token", try! Regex(#"\bshp(at|ca|pa|ss)_[a-fA-F0-9]{32}\b"#)),
        ("Telegram bot token", try! Regex(#"\b[0-9]{8,10}:AA[A-Za-z0-9_-]{33}\b"#)),
        ("JSON Web Token", try! Regex(#"\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"#)),
        ("Password in a link", try! Regex(#"\b[a-z][a-z0-9+.-]{1,15}://[^\s:/@]{1,64}:[^\s/@]{3,128}@"#)),
        ("Authorization header", try! Regex(#"(?i)\bauthorization:\s{0,4}(bearer|basic|token)\s{1,4}[A-Za-z0-9._~+/-]{12,}"#)),
    ]

    /// Text that mentions a credential, which may or may not include one.
    private static let possibleFormats: [(String, Regex<AnyRegexOutput>)] = [
        ("Password or key", try! Regex(#"(?i)\b(password|passwd|pwd|passphrase|secret|api[_-]?key|apikey|access[_-]?token|auth[_-]?token|client[_-]?secret|private[_-]?key)["']?\s{0,4}[:=]\s{0,4}["']?[^\s"']{6,}"#)),
        ("Password", try! Regex(#"(?i)\b(password|passcode|passphrase|pin)\b[^\n]{0,30}\bis\b\s{0,4}\S{4,}"#)),
        ("Bearer token", try! Regex(#"(?i)\bbearer\s{1,4}[A-Za-z0-9._~+/-]{20,}"#)),
    ]

    /// Most text that is checked, so huge items stay fast.
    private static let maxCheckedLength = 20_000

    static func detect(in text: String) -> SecretFinding? {
        let sample = String(text.prefix(maxCheckedLength))
        for (reason, pattern) in knownFormats where sample.contains(pattern) {
            return SecretFinding(reason: reason, isCertain: true)
        }
        for (reason, pattern) in possibleFormats where sample.contains(pattern) {
            return SecretFinding(reason: reason, isCertain: false)
        }
        if looksLikeRandomToken(sample.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return SecretFinding(reason: "Looks like a password", isCertain: false)
        }
        return nil
    }

    /// A single word that looks generated rather than written: long enough, mixing kinds of characters, and not something common like a UUID, hash, version, path or address.
    static func looksLikeRandomToken(_ s: String) -> Bool {
        guard s.count >= 8, s.count <= 256, !s.contains(where: { $0.isWhitespace }) else { return false }
        if s.contains("://") || s.hasPrefix("/") || s.hasPrefix("~") || s.hasPrefix(".") { return false }
        if s.wholeMatch(of: #/[^@]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}/#) != nil { return false }
        // UUIDs, hashes and other hex, versions, numbers and dates.
        if s.wholeMatch(of: #/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/#) != nil { return false }
        if s.wholeMatch(of: #/[0-9a-fA-F]+/#) != nil { return false }
        if s.wholeMatch(of: #/v?[0-9][0-9.]*([-+][0-9A-Za-z.-]*)?/#) != nil { return false }
        if s.wholeMatch(of: #/[0-9.,:\/+-]+/#) != nil { return false }

        let classes = [
            s.contains(where: { $0.isLowercase }),
            s.contains(where: { $0.isUppercase }),
            s.contains(where: { $0.isNumber }),
            s.contains(where: { !$0.isLetter && !$0.isNumber }),
        ].filter({ $0 }).count
        guard classes >= 3 || (classes == 2 && s.count >= 24) else { return false }

        // Words and identifiers change between letters, digits and symbols rarely; generated strings do so often.
        let chars = Array(s)
        var switches = 0
        for i in 1..<chars.count where characterClass(chars[i]) != characterClass(chars[i - 1]) {
            switches += 1
        }
        let switchRate = Double(switches) / Double(chars.count - 1)
        return switchRate >= 0.3 && entropy(of: s) >= 3.0
    }

    private static func characterClass(_ c: Character) -> Int {
        if c.isLowercase { return 0 }
        if c.isUppercase { return 1 }
        if c.isNumber { return 2 }
        return 3
    }

    /// Shannon entropy in bits per character.
    private static func entropy(of s: String) -> Double {
        let counts = Dictionary(grouping: s, by: { $0 }).mapValues(\.count)
        let n = Double(s.count)
        return counts.values.reduce(0, { total, count in
            let p = Double(count) / n
            return total - p * log2(p)
        })
    }

    /// Hides most of the text, keeping just enough to recognise it, e.g. `ghp_••••••••3f`.
    static func mask(_ text: String) -> String {
        let line = text.split(whereSeparator: \.isNewline).first.map({ $0.trimmingCharacters(in: .whitespaces) }) ?? ""
        let shown = line.count >= 16 ? 4 : (line.count >= 8 ? 2 : 0)
        let tail = line.count >= 16 ? String(line.suffix(2)) : ""
        return String(line.prefix(shown)) + "••••••••" + tail
    }
}
