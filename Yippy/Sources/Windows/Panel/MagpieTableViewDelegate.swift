//
//  MagpieTableViewDelegate.swift
//  Magpie
//

import Foundation

protocol MagpieTableViewDelegate {
    
    func magpieTableView(_ magpieTableView: MagpieTableView, selectedDidChange selected: Int?)
    
    func magpieTableView(_ magpieTableView: MagpieTableView, didMoveItem from: Int, to: Int)
}
