//
//  HistoryTests.swift
//  MagpieTests
//

import Testing
import AppKit
import SwiftData
@testable import Magpie

/// History behaviour against an in-memory SwiftData store.
@Suite struct HistoryTests {
    
    let container: ModelContainer
    let history: History
    
    init() throws {
        container = try HistoryStore.makeContainer(inMemory: true)
        history = History(container: container, maxItems: 100, persistsSettings: false)
    }
    
    private func text(_ string: String) -> [NSPasteboard.PasteboardType: Data] {
        return [.string: Data(string.utf8)]
    }
    
    private func strings(_ history: History) -> [String?] {
        return history.items.map({ $0.getPlainString() })
    }
    
    @Test func newItemsGoOnTop() {
        history.insert(data: text("one"), sourceBundleId: nil)
        history.insert(data: text("two"), sourceBundleId: "com.apple.Safari")
        
        #expect(strings(history) == ["two", "one"])
        #expect(history.items[0].sourceBundleId == "com.apple.Safari")
    }
    
    @Test func orderAndMetadataSurviveReloading() {
        history.insert(data: text("a"), sourceBundleId: nil)
        history.insert(data: text("b"), sourceBundleId: nil)
        history.insert(data: text("c"), sourceBundleId: nil)
        history.moveItem(at: 2, to: 0)
        history.setPinned(true, forItemAt: 1)
        
        let reloaded = History(container: container, persistsSettings: false)
        #expect(strings(reloaded) == ["a", "c", "b"])
        #expect(reloaded.items.map(\.isPinned) == [false, true, false])
    }
    
    @Test func repeatedMovesBetweenTheSameNeighboursKeepOrder() {
        for s in ["a", "b", "c", "d"] {
            history.insert(data: text(s), sourceBundleId: nil)
        }
        // Enough moves to exhaust Double precision between two neighbours and force renumbering.
        for _ in 0..<80 {
            history.moveItem(at: 3, to: 1)
        }
        let expected = strings(history)
        let reloaded = History(container: container, persistsSettings: false)
        #expect(strings(reloaded) == expected)
    }
    
    @Test func trimmingRemovesOldestUnpinnedItems() {
        for s in ["1", "2", "3", "4"] {
            history.insert(data: text(s), sourceBundleId: nil)
        }
        // Pin the oldest item; it must survive the trim.
        history.setPinned(true, forItemAt: 3)
        history.setMaxItems(2)
        
        #expect(strings(history) == ["4", "3", "1"])
    }
    
    @Test func clearKeepsPinnedItems() {
        history.insert(data: text("keep"), sourceBundleId: nil)
        history.setPinned(true, forItemAt: 0)
        history.insert(data: text("drop"), sourceBundleId: nil)
        history.clear()
        
        #expect(strings(history) == ["keep"])
    }
    
    @Test func deletedItemsStopReadingData() {
        let item = history.insert(data: text("gone"), sourceBundleId: nil)
        history.deleteItem(at: 0)
        
        #expect(history.items.isEmpty)
        #expect(item.isRemoved)
        #expect(item.getPlainString() == nil)
    }
    
    @Test func subscribersHearAboutChanges() {
        var changes = [String]()
        history.subscribe { _, change in
            switch change {
            case .initial: changes.append("initial")
            case .insert: changes.append("insert")
            case .delete: changes.append("delete")
            case .update: changes.append("update")
            default: changes.append("other")
            }
        }
        history.insert(data: text("x"), sourceBundleId: nil)
        history.setPinned(true, forItemAt: 0)
        history.deleteItem(at: 0)
        
        #expect(changes == ["initial", "insert", "update", "delete"])
    }
    
    // MARK: - Pasteboard
    
    private func pasteboard(_ fill: (NSPasteboard) -> Void) -> NSPasteboard {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("MagpieTests.\(UUID().uuidString)"))
        pasteboard.clearContents()
        fill(pasteboard)
        return pasteboard
    }
    
    @Test func copiesAreRecordedWithTheirSourceApp() {
        let board = pasteboard({ $0.setString("hello", forType: .string) })
        history.pasteboardDidChange(board, originBundleId: "com.apple.Notes")
        
        #expect(strings(history) == ["hello"])
        #expect(history.items[0].sourceBundleId == "com.apple.Notes")
        #expect(history.items[0].kind == .text)
    }
    
    @Test func copyingTheSameThingTwiceIsIgnored() {
        history.pasteboardDidChange(pasteboard({ $0.setString("same", forType: .string) }), originBundleId: nil)
        history.pasteboardDidChange(pasteboard({ $0.setString("same", forType: .string) }), originBundleId: nil)
        
        #expect(history.items.count == 1)
    }
    
    @Test func copiesFromExcludedAppsAreNotSaved() {
        history.excludedBundleIds = ["com.apple.Passwords"]
        history.pasteboardDidChange(pasteboard({ $0.setString("secret", forType: .string) }), originBundleId: "com.apple.Passwords")
        
        #expect(history.items.isEmpty)
    }
    
    @Test func concealedCopiesAreNotSaved() {
        let board = pasteboard({ board in
            let item = NSPasteboardItem()
            item.setString("hunter2", forType: .string)
            item.setString("", forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
            board.writeObjects([item])
        })
        history.pasteboardDidChange(board, originBundleId: nil)
        
        #expect(history.items.isEmpty)
    }
}
