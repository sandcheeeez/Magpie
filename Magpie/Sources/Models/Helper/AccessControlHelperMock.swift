//
//  AccessControlHelperMock.swift
//  Magpie
//

import Foundation
import Cocoa

class AccessControlHelperMock: AccessControlHelper {
    
    override func isControlGranted() -> Bool {
        return AccessControlMock.isControlGranted()
    }
    
    override func isControlGranted(showPopup: Bool) -> Bool {
        return AccessControlMock.isControlGranted()
    }
}
