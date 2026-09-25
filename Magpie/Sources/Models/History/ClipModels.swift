//
//  ClipModels.swift
//  Magpie
//

import Foundation
import SwiftData

/// A saved clipboard item.
@Model
final class ClipItem {
    
    #Index<ClipItem>([\.position])
    
    @Attribute(.unique) var id: UUID
    
    /// Sort key: higher is nearer the top of the history.
    var position: Double
    
    var copiedAt: Date
    
    /// Bundle id of the app that was frontmost when the item was copied.
    var sourceBundleId: String?
    
    /// Pinned items are never removed when the history exceeds its limit.
    var isPinned: Bool
    
    /// Text recognised in an image item. `""` means recognition ran and found nothing.
    var recognizedText: String?
    
    /// Raw value of `HistoryItemKind`.
    var kindRaw: String
    
    /// Case and diacritic folded text used for searching.
    var searchText: String
    
    /// The item's pasteboard data, one per type.
    @Relationship(deleteRule: .cascade, inverse: \ClipRepresentation.item)
    var representations: [ClipRepresentation] = []
    
    init(id: UUID = UUID(), position: Double, copiedAt: Date, sourceBundleId: String?, isPinned: Bool = false, recognizedText: String? = nil, kind: HistoryItemKind, searchText: String) {
        self.id = id
        self.position = position
        self.copiedAt = copiedAt
        self.sourceBundleId = sourceBundleId
        self.isPinned = isPinned
        self.recognizedText = recognizedText
        self.kindRaw = kind.rawValue
        self.searchText = searchText
    }
}

/// One pasteboard type's data for a `ClipItem`.
@Model
final class ClipRepresentation {
    
    /// The pasteboard type, e.g. `public.utf8-plain-text`.
    var type: String
    
    /// Stored outside the database when large, such as images.
    @Attribute(.externalStorage) var data: Data
    
    var item: ClipItem?
    
    init(type: String, data: Data) {
        self.type = type
        self.data = data
    }
}

/// Creates the SwiftData container for the history.
enum HistoryStore {
    
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([ClipItem.self, ClipRepresentation.self])
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        }
        else {
            try FileManager.default.createDirectory(at: Constants.urls.magpieAppSupport, withIntermediateDirectories: true)
            configuration = ModelConfiguration(schema: schema, url: Constants.urls.historyStore)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
