//
//  Search.swift
//  Magpie
//

import Foundation

/// How well a query matched an item. Lower ranks sort first.
enum SearchMatch: Comparable {
    /// Every word of the query appears in the text.
    case substring
    /// The query's characters appear in order, close together. `span` is how many characters the match covers.
    case fuzzy(span: Int)
}

/// Matches an already folded `query` against already folded `haystack` text.
///
/// Each whitespace separated word must appear as a substring for a `.substring` match. Otherwise, falls back to a fuzzy match of the whole query, which only counts if the matched characters are close together, so that short queries don't match every long piece of text.
func searchMatch(query: String, words: [Substring], haystack: String) -> SearchMatch? {
    if words.allSatisfy({ haystack.contains($0) }) {
        return .substring
    }
    
    let needle = Array(query.replacingOccurrences(of: " ", with: "").utf16)
    guard needle.count >= 2 else {
        return nil
    }
    let text = Array(haystack.utf16.prefix(2000))
    let maxSpan = max(needle.count * 3, needle.count + 5)
    var bestSpan: Int?
    
    for start in text.indices where text[start] == needle[0] {
        var n = 1
        var i = start + 1
        while n < needle.count && i < text.count && i - start < maxSpan {
            if text[i] == needle[n] {
                n += 1
            }
            i += 1
        }
        if n == needle.count {
            let span = i - start
            bestSpan = min(bestSpan ?? span, span)
            if span == needle.count { break }
        }
    }
    return bestSpan.map({ .fuzzy(span: $0) })
}
