//
//  AlerterMock.swift
//  MagpieTests
//

import XCTest
@testable import Magpie

class AlerterMock: Alerter {
    
    var expectation: XCTestExpectation!
    
    override func show(_ alertable: Alertable) {
        expectation.fulfill()
    }
}
