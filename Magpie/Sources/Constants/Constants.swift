//
//  Constants.swift
//  Magpie
//

import Foundation
import Cocoa

struct Constants {
    
    struct panel {
        static let menuWidth: CGFloat = 400
        static let menuHeight: CGFloat = 300
        static let maxCellHeight: CGFloat = 200
    }
    
    struct statusItemMenu {
        static let deleteKeyEquivalent = NSString(format: "%c", NSDeleteCharacter) as String
        static let leftArrowKeyEquivalent = NSString(format: "%C", 0x001c) as String
        static let rightArrowKeyEquivalent = NSString(format: "%C", 0x001d) as String
        static let downArrowKeyEquivalent = NSString(format: "%C", 0x001f) as String
        static let upArrowKeyEquivalent = NSString(format: "%C", 0x001e) as String
    }
    
    struct fonts {
        
        static var magpiePlainText: NSFont {
            return NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        }
        
        static var magpieFileNameText: NSFont {
            return NSFont.systemFont(ofSize: 12, weight: .medium)
        }
    }
    
    struct urls {
        static var applicationSupport: URL {
            return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        }
        
        static var magpieAppSupport: URL {
            return applicationSupport.appendingPathComponent(Bundle.main.bundleIdentifier!, isDirectory: true)
        }
        
        /// The SwiftData store holding the history.
        static var historyStore: URL {
            return magpieAppSupport.appendingPathComponent("History.store", isDirectory: false)
        }

        static var errorLog: URL {
            return magpieAppSupport.appendingPathComponent("error.log", isDirectory: false)
        }
        
        static var warningLog: URL {
            return magpieAppSupport.appendingPathComponent("warning.log", isDirectory: false)
        }
    }
    
    struct logging {
        
        static let historyErrorDomain = "MagpieHistoryErrorDomain"
        
        static let historyWarningDomain = "MagpieHistoryWarningDomain"
    }
    
    struct system {
        
        static let maxHistoryItems = 5000
    }
    
    struct settings {
        
        /// `maxHistory` value meaning the history is never trimmed.
        static let unlimitedHistory = Int.max
        
        static let maxHistoryItemsOptions = [50, 100, 200, 500, 750, 1000, 1500, 2500, 5000, 10000, unlimitedHistory]
        
        static let maxHistoryItemsDefaultIndex = 3
        
        static let maxHistoryItemsDefault = Constants.settings.maxHistoryItemsOptions[Constants.settings.maxHistoryItemsDefaultIndex]
    }
}
