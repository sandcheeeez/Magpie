//
//  WaitingViewController.swift
//  Magpie
//

import Foundation
import Cocoa

class WaitingViewController: NSViewController {
    
    @IBAction func allowAccessClicked(_ sender: Any) {
        _ = Helper.isControlGranted(showPopup: true)
    }
}
