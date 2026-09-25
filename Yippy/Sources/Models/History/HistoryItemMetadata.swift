//
//  HistoryItemMetadata.swift
//  Yippy
//

import Foundation
import Cocoa

/// Information about a history item that isn't part of its pasteboard data.
struct HistoryItemMetadata: Codable, Equatable {

    /// When the item was copied.
    var copiedAt: Date

    /// Bundle id of the app that was frontmost when the item was copied.
    var sourceBundleId: String?

    /// Pinned items are never removed when the history exceeds its limit.
    var isPinned = false

    /// Text recognised in an image item. `""` means recognition ran and found nothing.
    var recognizedText: String?
}

/// Persists `HistoryItemMetadata` for all items in a single JSON file, keyed by item id.
///
/// Stored outside the history directory because every entry in that directory is treated as an item.
class HistoryMetadataStore {

    static let `default` = HistoryMetadataStore(url: Constants.urls.historyMetadata)

    let url: URL

    private let queue = DispatchQueue(label: "HistoryMetadataStoreQueue", qos: .utility)
    private var pendingSave: DispatchWorkItem?

    init(url: URL) {
        self.url = url
    }

    func load() -> [UUID: HistoryItemMetadata] {
        guard let data = try? Data(contentsOf: url) else {
            return [:]
        }
        do {
            return try Self.decoder.decode([UUID: HistoryItemMetadata].self, from: data)
        }
        catch {
            YippyWarning(localizedDescription: "Failed to read history metadata: \(error.localizedDescription)").log(with: WarningLogger.general)
            return [:]
        }
    }

    /// Saves the metadata of `items`, coalescing saves that happen in quick succession.
    func save(_ items: [HistoryItem]) {
        let snapshot = Dictionary(uniqueKeysWithValues: items.map({ ($0.fsId, $0.metadata) }))
        pendingSave?.cancel()
        let work = DispatchWorkItem { [url] in
            Self.write(snapshot, to: url)
        }
        pendingSave = work
        queue.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    /// Writes any pending save immediately. Call before the app terminates.
    func flush() {
        guard let work = pendingSave else { return }
        pendingSave = nil
        work.cancel()
        queue.sync {}
        work.perform()
    }

    private static func write(_ metadata: [UUID: HistoryItemMetadata], to url: URL) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try encoder.encode(metadata).write(to: url, options: .atomic)
        }
        catch {
            YippyError(localizedDescription: "Failed to save history metadata: \(error.localizedDescription)").log(with: ErrorLogger.general)
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

/// The broad kind of content an item holds, used for filtering and display.
enum HistoryItemKind: String, CaseIterable {
    case text
    case link
    case image
    case file
    case color
}

extension HistoryItem {

    /// Whether the string is a single URL (rather than text containing one).
    static func isLink(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count < 2048, trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return detector.firstMatch(in: trimmed, options: [], range: range)?.range == range
    }
}
