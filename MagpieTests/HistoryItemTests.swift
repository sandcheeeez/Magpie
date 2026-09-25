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
}
