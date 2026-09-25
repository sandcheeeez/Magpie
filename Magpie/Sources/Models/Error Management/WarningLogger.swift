//
//  WarningLogger.swift
//  Magpie
//

import Foundation

class WarningLogger: Logger {
    
    static let general = WarningLogger(url: Constants.urls.warningLog)
}
