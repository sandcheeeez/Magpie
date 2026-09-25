//
//  SearchTests.swift
//  MagpieTests
//

import Testing
import AppKit
@testable import Magpie

@Suite struct SearchMatchTests {
    
    private func match(_ query: String, _ haystack: String) -> SearchMatch? {
        let folded = HistoryItem.foldForSearch(query)
        return searchMatch(query: folded, words: folded.split(separator: " "), haystack: HistoryItem.foldForSearch(haystack))
    }
    
    @Test func allWordsMatchAsSubstrings() {
        #expect(match("hello", "Say Hello world") == .substring)
        #expect(match("world hello", "hello there world") == .substring)
        #expect(match("cafe", "Café au lait") == .substring)
    }
    
    @Test func closeCharactersMatchFuzzily() {
        #expect(match("hlo", "hello") == .fuzzy(span: 5))
        #expect(match("gthb", "https://github.com/foo") != nil)
    }
    
    @Test func spreadOutCharactersDoNotMatch() {
        let long = "a very long text " + String(repeating: "lorem ipsum ", count: 50) + " x and much later z"
        #expect(match("xz", long) == nil)
        #expect(match("abc", "zzz") == nil)
    }
    
    @Test func substringMatchesRankFirst() {
        #expect(SearchMatch.substring < .fuzzy(span: 2))
        #expect(SearchMatch.fuzzy(span: 3) < .fuzzy(span: 9))
    }
}

@Suite struct SearchEngineTests {
    
    let history: History
    
    init() throws {
        history = History(container: try HistoryStore.makeContainer(inMemory: true), persistsSettings: false)
        history.insert(data: [.string: Data("the quick brown fox".utf8)], sourceBundleId: nil)
        history.insert(data: [.string: Data("https://apple.com".utf8)], sourceBundleId: nil)
        history.insert(data: [.string: Data("quack".utf8)], sourceBundleId: nil)
        history.setPinned(true, forItemAt: 0)
    }
    
    private func search(_ query: String, filter: HistoryFilter = .all) async -> [String?] {
        let engine = SearchEngine()
        let items = history.items
        let results = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                engine.search(query: query, filter: filter, items: items) { continuation.resume(returning: $0) }
            }
        }
        return results.map({ $0.getPlainString() })
    }
    
    @Test func filtersByKind() async {
        #expect(await search("", filter: .links) == ["https://apple.com"])
        #expect(await search("", filter: .pinned) == ["quack"])
    }
    
    @Test func substringMatchesComeBeforeFuzzyMatches() async {
        // "quick" contains "qck" loosely; "quack" doesn't contain it at all but matches fuzzily too.
        #expect(await search("quick") == ["the quick brown fox"])
        #expect(await search("qck").first == "quack")
    }
}
