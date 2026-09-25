//
//  KeyPressHelperMock.swift
//  Magpie
//

import Foundation
import ApplicationServices

class KeyPressHelperMock: KeyPressHelper {
    
    override func press(keyCode: CGKeyCode, flags: CGEventFlags) {
        KeyPressMock.keyPress(keyCode: keyCode, flags: flags)
    }
}
