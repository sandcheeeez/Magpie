//
//  HistoryItem.swift
//  Magpie
//

import Foundation
import Cocoa
import Quartz

/// The broad kind of content an item holds, used for filtering and display.
enum HistoryItemKind: String, CaseIterable {
    case text
    case code
    case link
    case image
    case file
    case color
}

/// An item in the history, as used by the UI and the pasteboard. Wraps the stored `ClipItem`.
///
/// The small fields are copied from the model, so an item that has been deleted from the store can still be displayed safely (for example by a preview that is closing). Its data is no longer available once `isRemoved` is set.
class HistoryItem: NSObject {

    // MARK: - Attributes

    let model: ClipItem

    let id: UUID

    /// The types of pasteboard data the item contains.
    let types: [NSPasteboard.PasteboardType]

    let kind: HistoryItemKind

    /// Case and diacritic folded text used for searching, excluding recognised text.
    let searchableText: String

    let copiedAt: Date
    
    /// Detected tags, such as "Email" or a code language.
    let tags: [String]
    
    let characterCount: Int?
    
    let lineCount: Int?
    
    let codeLanguage: String?
    
    /// Total size of the item's data.
    let byteCount: Int

    let sourceBundleId: String?

    /// Pinned items are never removed when the history exceeds its limit. Change it through `History`.
    var isPinned: Bool {
        didSet { if !isRemoved { model.isPinned = isPinned } }
    }

    /// Text recognised in an image. `""` means recognition ran and found nothing. Change it through `History`.
    var recognizedText: String? {
        didSet { if !isRemoved { model.recognizedText = recognizedText } }
    }

    /// Set by `History` just before the model is deleted. Data can't be read after this.
    var isRemoved = false

    static let historyItemIdType = NSPasteboard.PasteboardType(rawValue: "com.sandcheeeez.Magpie.historyItemId")

    /// Static definition of whether the history items should write RTF data to the pasteboard.
    ///
    /// This value is used when determining the writable types for an item.
    static var pastesRichText = true


    // MARK: - Constructors

    init(model: ClipItem) {
        self.model = model
        self.id = model.id
        self.types = model.representations.map({ NSPasteboard.PasteboardType($0.type) })
        self.kind = HistoryItemKind(rawValue: model.kindRaw) ?? .text
        self.searchableText = model.searchText
        self.copiedAt = model.copiedAt
        self.tags = model.tags
        self.characterCount = model.characterCount
        self.lineCount = model.lineCount
        self.codeLanguage = model.codeLanguage
        self.byteCount = model.byteCount
        self.sourceBundleId = model.sourceBundleId
        self.isPinned = model.isPinned
        self.recognizedText = model.recognizedText
    }

    /// Creates a model for new pasteboard data, analysing its content.
    static func makeModel(data: [NSPasteboard.PasteboardType: Data], position: Double, copiedAt: Date = Date(), sourceBundleId: String?) -> ClipItem {
        let model = ClipItem(position: position, copiedAt: copiedAt, sourceBundleId: sourceBundleId, analysis: ClipAnalyzer.analyze(data))
        model.representations = data.map({ ClipRepresentation(type: $0.key.rawValue, data: $0.value) })
        return model
    }
    
    
    /// A short one-line description, e.g. for lists in Settings.
    var displayTitle: String {
        switch kind {
        case .file:
            return getFileUrl()?.lastPathComponent ?? "File"
        case .image:
            if let text = recognizedText?.split(separator: "\n").first, !text.isEmpty {
                return "Image: \(text)"
            }
            return "Image"
        case .color:
            return getPlainString()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Colour"
        case .text, .code, .link:
            let text = HistoryItemText.getString(forItem: self)
            let line = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
            return String(line.trimmingCharacters(in: .whitespaces).prefix(80))
        }
    }
    
    
    // MARK: - Data

    /// Returns the data for given type, or `nil` if the item doesn't have it or has been removed.
    func data(forType type: NSPasteboard.PasteboardType) -> Data? {
        guard !isRemoved, types.contains(type) else {
            return nil
        }
        return model.representations.first(where: { $0.type == type.rawValue })?.data
    }


    // MARK: - Search
    
    /// Limits how much of very long text is searched, keeping search fast.
    static let maxSearchableLength = 20_000

    static func foldForSearch(_ str: String) -> String {
        return str.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
    }

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


    // MARK: - Typed accessors

    func getImage() -> NSImage? {
        return getTiffImage() ?? getPng()
    }

    func getTiffImage() -> NSImage? {
        guard let tiffData = data(forType: .tiff) else { return nil }
        return NSImage(data: tiffData)
    }

    func getPlainString() -> String? {
        guard let data = data(forType: .string) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func getRtfAttributedString() -> NSAttributedString? {
        guard let data = data(forType: .rtf) else { return nil }
        return NSAttributedString(rtf: data, documentAttributes: nil)
    }

    func getHtmlRawString() -> String? {
        guard let data = data(forType: .html) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func getUrl() -> URL? {
        guard let data = data(forType: .URL) else { return nil }
        return URL(dataRepresentation: data, relativeTo: nil)
    }

    func getFileUrl() -> URL? {
        guard let data = data(forType: .fileURL) else { return nil }
        return URL(dataRepresentation: data, relativeTo: nil)
    }

    func getPdf() -> PDFDocument? {
        guard let data = data(forType: .pdf) else { return nil }
        return PDFDocument(data: data)
    }

    func getPng() -> NSImage? {
        guard let data = data(forType: .png) else { return nil }
        return NSImage(data: data)
    }

    func getThumbnailImage() -> NSImage? {
        var image: NSImage?
        DispatchQueue.global(qos: .userInteractive).sync {
            guard let url = getFileUrl() else { return }
            let ref = QLThumbnailCreate(kCFAllocatorDefault, url as CFURL, CGSize(width: 300, height: 300), [kQLThumbnailOptionIconModeKey: true] as CFDictionary)

            guard let thumbnail = ref?.takeRetainedValue() else { return }
            let cgImageRef = QLThumbnailCopyImage(thumbnail)
            guard let cgImage = cgImageRef?.takeRetainedValue() else { return }
            image = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        }
        return image
    }

    func getFileIcon() -> NSImage? {
        guard let url = getFileUrl() else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    /// The item's colour, from a native colour on the pasteboard or from colour text such as `#598CF2`.
    func getColor() -> NSColor? {
        guard let data = data(forType: .color) else {
            return kind == .color ? getPlainString().flatMap(ClipAnalyzer.color(fromText:)) : nil
        }
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: "com.sandcheeeez.Magpie.ColorDecode"))
        pasteboard.declareTypes([.color], owner: nil)
        pasteboard.setData(data, forType: .color)
        return NSColor(from: pasteboard)
    }

    private let richTextPasteboardTypes = [
        NSPasteboard.PasteboardType.rtf.rawValue,
        NSPasteboard.PasteboardType.html.rawValue,
        "public.utf16-external-plain-text",
        "org.chromium.web-custom-data",
    ]
}

// MARK: - HistoryItem+NSPasteboardWriting
extension HistoryItem: NSPasteboardWriting {
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return types.filter{
            HistoryItem.pastesRichText || !richTextPasteboardTypes.contains($0.rawValue)
        } + [Self.historyItemIdType]
    }

    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        if type == Self.historyItemIdType {
            return id.uuidString
        }
        return data(forType: type)
    }

    func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions {
        return .promised
    }
}
