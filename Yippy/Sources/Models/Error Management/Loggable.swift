//
//  Loggable.swift
//  Magpie
//

import Foundation

protocol Loggable {
    
    var localizedDescription: String { get }
    
    var consoleDescription: String { get }
    
    var logFileDescription: String { get }
    
    var domain: String { get }
    
    func log(with logger: Logger)
}

extension Loggable {
    
    func log(with logger: Logger) {
        logger.log(self)
    }
}
