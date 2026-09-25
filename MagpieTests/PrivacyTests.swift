//
//  PrivacyTests.swift
//  MagpieTests
//

import Testing
import Foundation

/// Magpie's history is sensitive, so the app must never talk to the network. This test fails if networking APIs appear in the app's source.
@Suite struct PrivacyTests {
    
    /// APIs that can send or fetch data over the network, or load remote content.
    static let forbidden = [
        "URLSession", "NSURLConnection", "URLRequest", "NSURLRequest",
        "import WebKit", "WKWebView", "WebView(",
        "import Network", "NWConnection", "NWListener", "CFSocket", "CFStream",
        "NSAttributedString(html:", "DocumentType.html",
        "import CloudKit", "import MultipeerConnectivity",
    ]
    
    @Test func appSourceMakesNoNetworkCalls() throws {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Magpie/Sources")
        let files = try #require(FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil))
            .compactMap({ $0 as? URL })
            .filter({ $0.pathExtension == "swift" })
        #expect(files.count > 20, "Couldn't find the app's source files")
        
        var violations = [String]()
        for file in files {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: .newlines)
            for (number, line) in lines.enumerated() where !line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                for api in Self.forbidden where line.contains(api) {
                    violations.append("\(file.lastPathComponent):\(number + 1) uses \(api)")
                }
            }
        }
        #expect(violations.isEmpty, "Networking APIs found: \(violations.joined(separator: ", "))")
    }
}
