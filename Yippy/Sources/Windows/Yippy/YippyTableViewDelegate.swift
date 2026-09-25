//
//  YippyTableViewDelegate.swift
//  Magpie
//

import Foundation

protocol YippyTableViewDelegate {
    
    func yippyTableView(_ yippyTableView: YippyTableView, selectedDidChange selected: Int?)
    
    func yippyTableView(_ yippyTableView: YippyTableView, didMoveItem from: Int, to: Int)
}
