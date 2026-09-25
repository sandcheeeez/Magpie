//
//  ErrorLogger.swift
//  Magpie
//

import Foundation

class ErrorLogger: Logger {
    
    static let general = ErrorLogger(url: Constants.urls.errorLog)
}


