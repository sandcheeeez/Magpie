//
//  TextRecognizer.swift
//  Yippy
//

import Foundation
import Vision

/// Recognises text in image history items on-device using Vision, so screenshots can be searched.
enum TextRecognizer {

    /// Returns the recognised text (`""` if none was found), or `nil` if the item has no image data or recognition failed.
    static func recognizeText(in item: HistoryItem) async -> String? {
        guard let data = item.data(forType: .png) ?? item.data(forType: .tiff) else {
            return nil
        }
        return await Task.detached(priority: .utility) {
            var request = RecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            do {
                let observations = try await request.perform(on: data)
                return observations
                    .compactMap({ $0.topCandidates(1).first?.string })
                    .joined(separator: "\n")
            }
            catch {
                YippyWarning(localizedDescription: "Text recognition failed for item \(item.fsId): \(error.localizedDescription)").log(with: WarningLogger.general)
                return nil
            }
        }.value
    }
}
