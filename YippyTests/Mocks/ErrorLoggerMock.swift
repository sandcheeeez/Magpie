//
//  ErrorLoggerMock.swift
//  MagpieTests
//

import XCTest
@testable import Magpie

class ErrorLoggerMock: ErrorLogger {
    
    var expectation: XCTestExpectation!
    
    init() {
        super.init(url: URL(fileURLWithPath: "test"))
    }
    
    override func log(_ loggable: Loggable) {
        expectation.fulfill()
    }
}
