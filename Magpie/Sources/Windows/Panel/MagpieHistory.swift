//
//  MagpieHistory.swift
//  Magpie
//

import Foundation
import Cocoa

class MagpieHistory {
    
    let history: History
    var items: [HistoryItem]
    
    let pasteboard: NSPasteboard
    
    init(history: History, items: [HistoryItem]) {
        self.history = history
        self.items = items
        self.pasteboard = NSPasteboard.general
    }
    
    /// The index in the full history of the item at `selected` in the displayed (possibly filtered) items.
    private func historyIndex(ofSelected selected: Int) -> Int? {
        return history.items.firstIndex(of: items[selected])
    }
    
    /// Pastes the item into the previously active app.
    ///
    /// - Parameter asPlainText: Paste only plain text, dropping formatting. Images paste their recognised text, if any.
    func paste(selected: Int, asPlainText: Bool = false) {
        let item = items[selected]
        
        // Internally action the pasteboard change
        // Our pasteboard monitor will detect the change
        // But our `History` will know that it has already been consumed
        if let i = historyIndex(ofSelected: selected) {
            history.moveItem(at: i, to: 0)
        }
        let newChangeCount = pasteboard.clearContents()
        history.recordPasteboardChange(withCount: newChangeCount)
        
        // Write object
        if asPlainText, let text = Self.plainText(for: item) {
            pasteboard.setString(text, forType: .string)
        }
        else {
            pasteboard.writeObjects([item])
        }
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.executePaste(startTime: Date())
            }
        }
    }
    
    static func plainText(for item: HistoryItem) -> String? {
        switch item.kind {
        case .image:
            guard let text = item.recognizedText, !text.isEmpty else { return nil }
            return text
        case .color:
            return nil
        case .file:
            return item.getFileUrl()?.path
        case .link, .text:
            return item.getPlainString() ?? item.getRtfAttributedString()?.string ?? item.getUrl()?.absoluteString
        }
    }
    
    func togglePin(selected: Int) {
        guard let i = historyIndex(ofSelected: selected) else { return }
        history.setPinned(!history.items[i].isPinned, forItemAt: i)
    }
    
    private func executePaste(startTime: Date) {
        if NSApp.isActive {
            if Date().timeIntervalSince(startTime) > 2 {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.03) {
                self.executePaste(startTime: startTime)
            }
        }
        else {
            Helper.pressCommandV()
        }
    }
    
    /// Returns the next item to select
    func delete(selected: Int) -> Int? {
        guard let i = historyIndex(ofSelected: selected) else { return selected }
        history.deleteItem(at: i)
        if i == 0 {
            // If we want to remove this, then we may have to change the `HistoryItem` writingOptions() to not `.promised`, because if something is pasted from history, then deleted, it can no longer satisfy the promise.
            pasteboard.clearContents()
        }
        
        // Assume no selection
        var select: Int? = nil
        // If the deleted item is not the last in the list then keep the selection index the same.
        if selected < items.count - 1 {
            select = selected
        }
        // Otherwise if there is any items left, select the previous item
        else if selected > 0 {
            select = selected - 1
        }
        // No items, select nothing
        else {
            select = nil
        }
        return select
    }
    
    func move(from: Int, to: Int) {
        history.moveItem(at: from, to: to)
        
        if to == 0 {
            let newChangeCount = pasteboard.clearContents()
            history.recordPasteboardChange(withCount: newChangeCount)
            
            // Write object
            pasteboard.writeObjects([items[from]])
        }
    }
}

