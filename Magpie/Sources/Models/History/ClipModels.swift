//
//  ClipModels.swift
//  Magpie
//

import Foundation
import SwiftData
import AppKit

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
    
    /// Detected tags, such as "Email" or a code language.
    var tags: [String] = []
    
    var characterCount: Int?
    
    var lineCount: Int?
    
    var codeLanguage: String?
    
    /// Total size of the item's data.
    var byteCount: Int = 0
    
    /// The `ClipAnalyzer.version` that produced the fields above.
    var analysisVersion: Int = 0
    
    /// The item's pasteboard data, one per type.
    @Relationship(deleteRule: .cascade, inverse: \ClipRepresentation.item)
    var representations: [ClipRepresentation] = []
    
    init(id: UUID = UUID(), position: Double, copiedAt: Date, sourceBundleId: String?, isPinned: Bool = false, recognizedText: String? = nil, analysis: ClipAnalysis) {
        self.id = id
        self.position = position
        self.copiedAt = copiedAt
        self.sourceBundleId = sourceBundleId
        self.isPinned = isPinned
        self.recognizedText = recognizedText
        self.kindRaw = analysis.kind.rawValue
        self.searchText = analysis.searchText
        apply(analysis)
    }
    
    /// The item's data keyed by pasteboard type.
    var pasteboardData: [NSPasteboard.PasteboardType: Data] {
        return Dictionary(representations.map({ (NSPasteboard.PasteboardType($0.type), $0.data) }), uniquingKeysWith: { first, _ in first })
    }
    
    func apply(_ analysis: ClipAnalysis) {
        kindRaw = analysis.kind.rawValue
        searchText = analysis.searchText
        tags = analysis.tags
        characterCount = analysis.characterCount
        lineCount = analysis.lineCount
        codeLanguage = analysis.codeLanguage
        byteCount = analysis.byteCount
        analysisVersion = ClipAnalyzer.version
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
    
    /// - Parameter readOnly: Open without saving, for readers such as the MCP server that run alongside the app.
    static func makeContainer(inMemory: Bool = false, readOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema([ClipItem.self, ClipRepresentation.self])
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        }
        else {
            try FileManager.default.createDirectory(at: Constants.urls.magpieAppSupport, withIntermediateDirectories: true)
            configuration = ModelConfiguration(schema: schema, url: Constants.urls.historyStore, allowsSave: !readOnly)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
