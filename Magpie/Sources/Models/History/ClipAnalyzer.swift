//
//  ClipAnalyzer.swift
//  Magpie
//

import Foundation
import AppKit

/// What Magpie works out about an item's content when it is copied. Everything here is computed on-device.
struct ClipAnalysis: Equatable {
    var kind: HistoryItemKind
    /// Detected tags, such as "Email" or a code language like "Swift".
    var tags: [String]
    var searchText: String
    /// Characters in the item's text, for text, code and links.
    var characterCount: Int?
    /// Lines of code, for code.
    var lineCount: Int?
    var codeLanguage: String?
    /// Total size of all the item's pasteboard data.
    var byteCount: Int
}

/// Classifies pasteboard data: its kind, tags, code language and size.
enum ClipAnalyzer {

    /// Increase when analysis changes, so stored items are analysed again on the next launch.
    static let version = 1

    static func analyze(_ data: [NSPasteboard.PasteboardType: Data]) -> ClipAnalysis {
        let byteCount = data.values.reduce(0, { $0 + $1.count })
        let text = data[.string].flatMap({ String(data: $0, encoding: .utf8) })
            ?? data[.rtf].flatMap({ NSAttributedString(rtf: $0, documentAttributes: nil)?.string })

        var analysis = ClipAnalysis(kind: .text, tags: [], searchText: "", byteCount: byteCount)

        if let url = data[.fileURL].flatMap({ URL(dataRepresentation: $0, relativeTo: nil) }) {
            analysis.kind = .file
            analysis.searchText = HistoryItem.foldForSearch(url.lastPathComponent + "\n" + url.path)
            return analysis
        }
        if data[.color] != nil {
            analysis.kind = .color
            return analysis
        }
        if data[.tiff] != nil || data[.png] != nil {
            analysis.kind = .image
            return analysis
        }

        guard let text = text else {
            if let url = data[.URL].flatMap({ URL(dataRepresentation: $0, relativeTo: nil) }) {
                analysis.kind = .link
                analysis.searchText = HistoryItem.foldForSearch(url.absoluteString)
            }
            return analysis
        }

        analysis.searchText = HistoryItem.foldForSearch(String(text.prefix(HistoryItem.maxSearchableLength)))
        analysis.characterCount = text.count

        if data[.URL] != nil || HistoryItem.isLink(text) {
            analysis.kind = .link
        }
        else if color(fromText: text) != nil {
            analysis.kind = .color
        }
        else if let language = codeLanguage(of: text) {
            analysis.kind = .code
            analysis.codeLanguage = language == unknownLanguage ? nil : language
            analysis.lineCount = text.split(separator: "\n", omittingEmptySubsequences: false).count
        }

        analysis.tags = tags(in: text, codeLanguage: analysis.codeLanguage)
        return analysis
    }


    // MARK: - Colours

    /// Parses a colour written as text: `#RGB`, `#RRGGBB`, `#RRGGBBAA`, `rgb()`/`rgba()` or `hsl()`/`hsla()`.
    static func color(fromText text: String) -> NSColor? {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard s.count <= 40 else { return nil }

        // Hex needs its #: bare digits are more often numbers, such as one-time codes, than colours.
        if let hex = s.wholeMatch(of: #/#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})/#)?.1 {
            var digits = String(hex)
            if digits.count == 3 {
                digits = digits.map({ "\($0)\($0)" }).joined()
            }
            guard let value = UInt64(digits, radix: 16) else { return nil }
            let hasAlpha = digits.count == 8
            let r = CGFloat((value >> (hasAlpha ? 24 : 16)) & 0xff) / 255
            let g = CGFloat((value >> (hasAlpha ? 16 : 8)) & 0xff) / 255
            let b = CGFloat((value >> (hasAlpha ? 8 : 0)) & 0xff) / 255
            let a = hasAlpha ? CGFloat(value & 0xff) / 255 : 1
            return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
        }

        if let m = s.wholeMatch(of: #/(rgb|hsl)a?\(\s*([\d.]+)%?\s*[, ]\s*([\d.]+)%?\s*[, ]\s*([\d.]+)%?\s*(?:[,\/]\s*([\d.]+%?)\s*)?\)/#),
           let x = Double(m.2), let y = Double(m.3), let z = Double(m.4) {
            var alpha = 1.0
            if let a = m.5 {
                alpha = a.hasSuffix("%") ? (Double(a.dropLast()) ?? 100) / 100 : (Double(a) ?? 1)
            }
            if m.1 == "rgb" {
                guard x <= 255, y <= 255, z <= 255 else { return nil }
                return NSColor(srgbRed: x / 255, green: y / 255, blue: z / 255, alpha: alpha)
            }
            guard x <= 360, y <= 100, z <= 100 else { return nil }
            // HSL to HSB, which NSColor supports directly.
            let l = z / 100, sl = y / 100
            let brightness = l + sl * min(l, 1 - l)
            let saturation = brightness == 0 ? 0 : 2 * (1 - l / brightness)
            return NSColor(hue: x / 360, saturation: saturation, brightness: brightness, alpha: alpha)
        }
        return nil
    }


    // MARK: - Code

    /// Returned by `codeLanguage(of:)` for text that looks like code in no particular language.
    static let unknownLanguage = "Code"

    private struct Language {
        let name: String
        /// Patterns and how strongly each suggests this language.
        let signals: [(Regex<AnyRegexOutput>, Int)]
    }

    private static let languages: [Language] = [
        Language(name: "Swift", signals: [
            (try! Regex(#"\bfunc \w+\s*(<[^>]*>)?\("#), 3), (try! Regex(#"\b(guard|if) let \w+"#), 3),
            (try! Regex(#"\bimport (Foundation|SwiftUI|UIKit|AppKit|SwiftData)\b"#), 4), (try! Regex(#"@(State|Observable|MainActor|objc|Published)\b"#), 3),
            (try! Regex(#"\b(struct|enum|extension|protocol) \w+"#), 2), (try! Regex(#"\) -> \w+"#), 2), (try! Regex(#"\blet \w+(: [\w\[\]?]+)? ="#), 1),
        ]),
        Language(name: "Python", signals: [
            (try! Regex(#"(?m)^\s*def \w+\(.*\):\s*$"#), 4), (try! Regex(#"(?m)^\s*(from \w[\w.]* )?import \w[\w.]*\s*$"#), 2),
            (try! Regex(#"(?m)^\s*(elif|except|with) .*:\s*$"#), 3), (try! Regex(#"\bself\.\w+"#), 1), (try! Regex(#"\bprint\(f?[\"']"#), 2),
            (try! Regex(#"(?m)^\s*class \w+(\(.*\))?:\s*$"#), 3), (try! Regex(#"__\w+__"#), 2),
        ]),
        Language(name: "JavaScript", signals: [
            (try! Regex(#"\b(const|let) \w+ = "#), 1), (try! Regex(#"=>\s*[{(]?"#), 2), (try! Regex(#"\bfunction\s*\w*\s*\("#), 3),
            (try! Regex(#"\bconsole\.log\("#), 4), (try! Regex(#"\b(require\(|module\.exports|export (default|const|function))"#), 3),
            (try! Regex(#"==="#), 2), (try! Regex(#"\bdocument\.\w+"#), 3),
        ]),
        Language(name: "TypeScript", signals: [
            (try! Regex(#"\binterface \w+ \{"#), 3), (try! Regex(#":\s*(string|number|boolean|void)\b"#), 3), (try! Regex(#"\b(type \w+ =|as const|readonly )"#), 2),
        ]),
        Language(name: "Shell", signals: [
            (try! Regex(#"^#!/(usr/)?bin/(env )?(ba|z)?sh"#), 5), (try! Regex(#"(?m)^\s*\$ \w"#), 3),
            (try! Regex(#"(?m)^\s*(sudo |git |brew |npm |npx |yarn |pip3? |cd |ls |mkdir |rm |cp |mv |curl |export |echo |xcodebuild |swift |cat |chmod |docker |kubectl )"#), 3),
            (try! Regex(#"\s--?[a-zA-Z][\w-]*"#), 1), (try! Regex(#"\s(\||&&|>>?)\s"#), 1),
        ]),
        Language(name: "SQL", signals: [
            (try! Regex(#"(?i)^\s*(select|insert into|update|delete from|create (table|index|view)|alter table|with \w+ as)\b"#), 4),
            (try! Regex(#"(?i)\b(from|where|join|group by|order by|values|set)\b"#), 1),
        ]),
        Language(name: "HTML", signals: [
            (try! Regex(#"(?i)<(!doctype html|html|head|body|div|span|p|a|ul|li|img|script|style)[\s>]"#), 4), (try! Regex(#"</\w+>"#), 2),
        ]),
        Language(name: "CSS", signals: [
            (try! Regex(#"(?m)^[ \t]*[.#]?[\w-][\w .#:>,-]*\{[ \t]*$"#), 2), (try! Regex(#"(?m)^\s*[\w-]+\s*:\s*[^;{}]+;\s*$"#), 2),
            (try! Regex(#"@(media|import|keyframes)\b"#), 3),
        ]),
        Language(name: "Go", signals: [
            (try! Regex(#"^package \w+"#), 4), (try! Regex(#"\bfunc (\(\w+ \*?\w+\) )?\w+\("#), 2), (try! Regex(#":= "#), 2), (try! Regex(#"\bfmt\.\w+\("#), 3),
        ]),
        Language(name: "Rust", signals: [
            (try! Regex(#"\bfn \w+\("#), 3), (try! Regex(#"\blet mut \w+"#), 3), (try! Regex(#"\b(println!|vec!|impl |pub fn|use std::)"#), 3),
        ]),
        Language(name: "C/C++", signals: [
            (try! Regex(#"(?m)^#include\s*[<\"]"#), 5), (try! Regex(#"\bint main\s*\("#), 3), (try! Regex(#"\b(std::|printf\(|malloc\()"#), 3),
        ]),
        Language(name: "Java", signals: [
            (try! Regex(#"\bpublic (static )?(class|void|final)\b"#), 3), (try! Regex(#"\bSystem\.out\.print"#), 4), (try! Regex(#"\bimport java\."#), 4),
        ]),
    ]

    /// Signs of code in any language: statement endings, braces and indentation.
    private static let genericSignals: [(Regex<AnyRegexOutput>, Int)] = [
        (try! Regex(#"(?m)[;{}]\s*$"#), 1), (try! Regex(#"(?m)^(    |\t)\S"#), 1), (try! Regex(#"[\w\]\)]\.\w+\("#), 1),
        (try! Regex(#"(==|!=|<=|>=|&&|\|\||->|=>)"#), 1),
    ]

    /// Returns the language of text that looks like code (`unknownLanguage` if the language is unclear), or `nil` for prose.
    static func codeLanguage(of text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 4, trimmed.count <= 100_000 else { return nil }
        let sample = String(trimmed.prefix(4000))

        if (sample.hasPrefix("{") || sample.hasPrefix("[")), trimmed.count < 1_000_000,
           let data = trimmed.data(using: .utf8), (try? JSONSerialization.jsonObject(with: data)) != nil {
            return "JSON"
        }

        var best: (name: String, score: Int)?
        for language in languages {
            let score = language.signals.reduce(0, { $0 + (sample.contains($1.0) ? $1.1 : 0) })
            if score > (best?.score ?? 0) {
                best = (language.name, score)
            }
        }
        let generic = genericSignals.reduce(0, { $0 + (sample.contains($1.0) ? $1.1 : 0) })

        // Prose rarely has these symbols; mostly-letter text is not code.
        let symbols = sample.filter({ "{}[]();=<>$#/\\|&*_".contains($0) }).count
        let symbolDensity = Double(symbols) / Double(max(sample.count, 1))

        if let best = best, best.score >= 4 || (best.score >= 3 && generic >= 1) {
            return best.name
        }
        if generic >= 3 && symbolDensity > 0.04 {
            return unknownLanguage
        }
        return nil
    }


    // MARK: - Tags

    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue
        | NSTextCheckingResult.CheckingType.phoneNumber.rawValue
        | NSTextCheckingResult.CheckingType.address.rawValue)

    /// Tags for useful things found in the text, and the code language if any.
    static func tags(in text: String, codeLanguage: String?) -> [String] {
        var tags = [String]()
        if let language = codeLanguage {
            tags.append(language)
        }
        // Data detection is for prose; code rarely contains meaningful phone numbers or addresses.
        guard codeLanguage == nil, let detector = detector else { return tags }
        let sample = String(text.prefix(5000))
        let matches = detector.matches(in: sample, range: NSRange(sample.startIndex..., in: sample))
        if matches.contains(where: { $0.resultType == .link && $0.url?.scheme == "mailto" }) {
            tags.append("Email")
        }
        if matches.contains(where: { $0.resultType == .phoneNumber }) {
            tags.append("Phone")
        }
        if matches.contains(where: { $0.resultType == .address }) {
            tags.append("Address")
        }
        return tags
    }
}
