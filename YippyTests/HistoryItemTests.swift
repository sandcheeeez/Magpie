//
//  HistoryItemTests.swift
//  MagpieTests
//

import Testing
import AppKit
@testable import Magpie

@Suite struct HistoryItemTests {
    
    @Test(arguments: [
        ("https://github.com/sandcheeeez/Magpie", true),
        ("  https://apple.com  ", true),
        ("see https://apple.com for details", false),
        ("just some words", false),
        ("", false),
    ])
    func linkDetection(string: String, isLink: Bool) {
        #expect(HistoryItem.isLink(string) == isLink)
    }
    
    @Test func kindComesFromTheData() {
        let url = URL(fileURLWithPath: "/Applications/Safari.app")
        #expect(HistoryItem.kind(of: [.fileURL: url.dataRepresentation]) == .file)
        #expect(HistoryItem.kind(of: [.tiff: Data([0])]) == .image)
        #expect(HistoryItem.kind(of: [.string: Data("https://apple.com".utf8)]) == .link)
        #expect(HistoryItem.kind(of: [.string: Data("hello".utf8)]) == .text)
    }
    
    @Test func searchTextIsFolded() {
        let text = HistoryItem.searchText(of: [.string: Data("Café ÜBER".utf8)], kind: .text)
        #expect(text == "cafe uber")
    }
    
    @Test func fileSearchTextIncludesTheName() {
        let url = URL(fileURLWithPath: "/Users/me/Documents/Report.pdf")
        let text = HistoryItem.searchText(of: [.fileURL: url.dataRepresentation], kind: .file)
        #expect(text.contains("report.pdf"))
    }
}
