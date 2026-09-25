//
//  YippyViewController.swift
//  Yippy
//
//  Created by Matthew Davidson on 26/7/19.
//  Copyright © 2019 MatthewDavidson. All rights reserved.
//

import Cocoa
import HotKey
import RxSwift
import RxRelay
import RxCocoa

struct Results {
    let items: [HistoryItem]
    let isSearchResult: Bool
}

class YippyViewController: NSViewController {
    
    @IBOutlet var yippyHistoryView: YippyTableView!
    
    @IBOutlet var itemGroupScrollView: HorizontalButtonsView!
    @IBOutlet var itemCountLabel: NSTextField!
    
    @IBOutlet var searchBar: NSTextField!
    
    var yippyHistory = YippyHistory(history: State.main.history, items: [])
    
    let searchEngine = SearchEngine()
    
    let filter = BehaviorRelay<HistoryFilter>(value: .all)
    
    let disposeBag = DisposeBag()
    
    var isPreviewShowing = false
    
    var itemGroups = BehaviorRelay<[String]>(value: HistoryFilter.allCases.map({ $0.title }))
    
    var isRichText = Settings.main.showsRichText
    
    let results = BehaviorRelay(value: Results(items: [], isSearchResult: false))
    let selected = BehaviorRelay<Int?>(value: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        yippyHistoryView.yippyDelegate = self
        
        State.main.history.subscribe(onNext: onHistoryChange)
        
        State.main.showsRichText.distinctUntilChanged().subscribe(onNext: onShowsRichText).disposed(by: disposeBag)
        
        styleHeader()
        itemGroupScrollView.symbolNames = HistoryFilter.allCases.map({ $0.symbolName })
        itemGroupScrollView.innerPadding = 6
        itemGroupScrollView.bind(toData: itemGroups.asObservable()).disposed(by: disposeBag)
        itemGroupScrollView.bind(toSelected: filter.map({ $0.rawValue })).disposed(by: disposeBag)
        itemGroupScrollView.onSelect = { [weak self] in
            self?.filter.accept(HistoryFilter(rawValue: $0) ?? .all)
        }
        filter.distinctUntilChanged().skip(1).subscribe(onNext: { [weak self] _ in
            self?.runSearch()
        }).disposed(by: disposeBag)
        
        yippyHistoryView.menu = makeContextMenu()
        
        Observable.combineLatest(
            results,
            selected.distinctUntilChanged().withPrevious(startWith: nil)
        )
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: onAllChange)
            .disposed(by: disposeBag)
        
        searchBar.delegate = self
        
        // TODO: Fix hack to make onAllChange run initially
        selected.accept(1)
        resetSelected()
        
        YippyHotKeys.downArrow.onDown(goToNextItem)
        YippyHotKeys.downArrow.onLong(goToNextItem)
        YippyHotKeys.pageDown.onDown(goToNextItem)
        YippyHotKeys.pageDown.onLong(goToNextItem)
        YippyHotKeys.upArrow.onDown(goToPreviousItem)
        YippyHotKeys.upArrow.onLong(goToPreviousItem)
        YippyHotKeys.pageUp.onDown(goToPreviousItem)
        YippyHotKeys.pageUp.onLong(goToPreviousItem)
        YippyHotKeys.escape.onDown(close)
        YippyHotKeys.return.onDown(pasteSelected)
        YippyHotKeys.ctrlAltCmdLeftArrow.onDown { State.main.panelPosition.accept(.left) }
        YippyHotKeys.ctrlAltCmdRightArrow.onDown { State.main.panelPosition.accept(.right) }
        YippyHotKeys.ctrlAltCmdDownArrow.onDown { State.main.panelPosition.accept(.bottom) }
        YippyHotKeys.ctrlAltCmdUpArrow.onDown { State.main.panelPosition.accept(.top) }
        YippyHotKeys.ctrlDelete.onDown(deleteSelected)
        YippyHotKeys.ctrlSpace.onDown(togglePreview)
        YippyHotKeys.cmdBackslash.onDown(focusSearchBar)
        YippyHotKeys.optionReturn.onDown(pasteSelectedAsPlainText)
        YippyHotKeys.cmdP.onDown(togglePinSelected)
        YippyHotKeys.cmdLeftArrow.onDown { self.cycleFilter(by: -1) }
        YippyHotKeys.cmdRightArrow.onDown { self.cycleFilter(by: 1) }
        
        // Paste hot keys
        YippyHotKeys.cmd0.onDown { self.shortcutPressed(key: 0) }
        YippyHotKeys.cmd1.onDown { self.shortcutPressed(key: 1) }
        YippyHotKeys.cmd2.onDown { self.shortcutPressed(key: 2) }
        YippyHotKeys.cmd3.onDown { self.shortcutPressed(key: 3) }
        YippyHotKeys.cmd4.onDown { self.shortcutPressed(key: 4) }
        YippyHotKeys.cmd5.onDown { self.shortcutPressed(key: 5) }
        YippyHotKeys.cmd6.onDown { self.shortcutPressed(key: 6) }
        YippyHotKeys.cmd7.onDown { self.shortcutPressed(key: 7) }
        YippyHotKeys.cmd8.onDown { self.shortcutPressed(key: 8) }
        YippyHotKeys.cmd9.onDown { self.shortcutPressed(key: 9) }
        
        bindHotKeyToYippyWindow(YippyHotKeys.downArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.upArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.return, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.escape, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.pageDown, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.pageUp, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdLeftArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdRightArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdDownArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlAltCmdUpArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd0, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd1, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd2, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd3, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd4, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd5, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd6, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd7, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd8, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmd9, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlDelete, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.ctrlSpace, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.optionReturn, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmdP, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmdLeftArrow, disposeBag: disposeBag)
        bindHotKeyToYippyWindow(YippyHotKeys.cmdRightArrow, disposeBag: disposeBag)
        
        searchBar.resignFirstResponder()
    }
    
    private func styleHeader() {
        if let title = view.subviews.compactMap({ $0 as? NSTextField }).first(where: { $0.stringValue == "Yippy" }) {
            title.font = NSFont.systemFont(ofSize: 17, weight: .bold).rounded
        }
        itemCountLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        itemCountLabel.textColor = .tertiaryLabelColor
        
        searchBar.font = .systemFont(ofSize: 13)
        searchBar.bezelStyle = .roundedBezel
        searchBar.placeholderAttributedString = NSAttributedString(string: "Search text, apps and images   ⌘\\", attributes: [
            .foregroundColor: NSColor.placeholderTextColor,
            .font: NSFont.systemFont(ofSize: 13),
        ])
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Refresh relative copy times ("2 min ago").
        yippyHistoryView.redisplayVisible(yippyItems: yippyHistory.items)
        
        isPreviewShowing = false
        resetSelected()
    }
    
    func resetSelected() {
        if yippyHistory.items.count > 0 {
            selected.accept(0)
        }
        else {
            selected.accept(nil)
        }
    }
    
    var isFiltered: Bool {
        return !searchBar.stringValue.trimmingCharacters(in: .whitespaces).isEmpty || filter.value != .all
    }
    
    func onHistoryChange(_ history: [HistoryItem], change: History.Change) {
        if case .update(let i) = change {
            // Metadata changed; the item may now be in or out of the filter (e.g. unpinned while viewing Pinned).
            if isFiltered {
                runSearch()
            }
            if let row = yippyHistory.items.firstIndex(of: history[i]) {
                yippyHistoryView.reloadItem(row)
            }
            return
        }
        if isFiltered {
            runSearch()
        }
        else {
            results.accept(Results(items: history, isSearchResult: false))
            switch change {
            case .insert(let i):
                if i == 0 {
                    incrementSelected()
                }
                break;
            default: break;
            }
        }
    }
    
    func onAllChange(_ results: Results, _ selected: (Int?, Int?)) {
        if results.items != self.yippyHistory.items {
                if results.isSearchResult {
                    self.itemCountLabel.stringValue = "\(results.items.count) \(results.items.count == 1 ? "match" : "matches")"
                }
                else {
                    self.itemCountLabel.stringValue = "\(results.items.count) items"
                }
                
                self.yippyHistory = YippyHistory(history: State.main.history, items: results.items)
                self.yippyHistoryView.allowsReordering = !results.isSearchResult
                self.yippyHistoryView.reloadData(self.yippyHistory.items, isRichText: self.isRichText)
            }
        
        if let previous = selected.0 {
            self.yippyHistoryView.deselectItem(previous)
            self.yippyHistoryView.reloadItem(previous)
        }
        if let selected = selected.1 {
            let currentSelection = self.yippyHistoryView.selected
            if currentSelection == nil || currentSelection != selected {
                self.yippyHistoryView.selectItem(selected)
            }
            self.yippyHistoryView.reloadItem(selected)
            
            if self.isPreviewShowing && selected < self.yippyHistory.items.count {
                State.main.previewHistoryItem.accept(self.yippyHistory.items[selected])
            }
        }
    }
    
    func onShowsRichText(_ showsRichText: Bool) {
        isRichText = showsRichText
        yippyHistoryView.reloadData(yippyHistory.items, isRichText: isRichText)
    }
    
    func bindHotKeyToYippyWindow(_ hotKey: YippyHotKey, disposeBag: DisposeBag) {
        State.main.isHistoryPanelShown
            .distinctUntilChanged()
            .subscribe(onNext: { [] in
                hotKey.isPaused = !$0
            })
            .disposed(by: disposeBag)
    }
    
    func goToNextItem() {
        incrementSelected()
    }
    
    func goToPreviousItem() {
        decrementSelected()
    }
    
    func pasteSelected() {
        if let selected = self.yippyHistoryView.selected {
            paste(selected: selected)
        }
    }
    
    func pasteSelectedAsPlainText() {
        if let selected = self.yippyHistoryView.selected {
            paste(selected: selected, asPlainText: true)
        }
    }
    
    func togglePinSelected() {
        if let selected = self.yippyHistoryView.selected {
            yippyHistory.togglePin(selected: selected)
        }
    }
    
    func cycleFilter(by offset: Int) {
        let count = HistoryFilter.allCases.count
        filter.accept(HistoryFilter(rawValue: (filter.value.rawValue + offset + count) % count) ?? .all)
    }
    
    func deleteSelected() {
        if let selected = self.yippyHistoryView.selected {
            self.selected.accept(yippyHistory.delete(selected: selected))
        }
    }
    
    func close() {
        isPreviewShowing = false
        State.main.isHistoryPanelShown.accept(false)
        State.main.previewHistoryItem.accept(nil)
        resetSelected()
    }
    
    func shortcutPressed(key: Int) {
        paste(selected: key)
    }
    
    // MARK: - Context menu
    
    private enum MenuAction: Int {
        case paste, pastePlainText, togglePin, preview, copyRecognizedText, openLink, revealInFinder, delete
    }
    
    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        return menu
    }
    
    private func menuItem(_ title: String, symbol: String, action: MenuAction) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(contextMenuAction(_:)), keyEquivalent: "")
        item.target = self
        item.tag = action.rawValue
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        return item
    }
    
    @objc private func contextMenuAction(_ sender: NSMenuItem) {
        let row = yippyHistoryView.clickedRow
        guard row >= 0, row < yippyHistory.items.count, let action = MenuAction(rawValue: sender.tag) else { return }
        let item = yippyHistory.items[row]
        switch action {
        case .paste:
            paste(selected: row)
        case .pastePlainText:
            paste(selected: row, asPlainText: true)
        case .togglePin:
            yippyHistory.togglePin(selected: row)
        case .preview:
            selected.accept(row)
            isPreviewShowing = true
            State.main.previewHistoryItem.accept(item)
        case .copyRecognizedText:
            guard let text = item.metadata.recognizedText else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        case .openLink:
            if let url = item.getUrl() ?? item.getPlainString().flatMap({ URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }) {
                close()
                NSWorkspace.shared.open(url)
            }
        case .revealInFinder:
            if let url = item.getFileUrl() {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        case .delete:
            let next = yippyHistory.delete(selected: row)
            if !isFiltered {
                selected.accept(next)
            }
        }
    }
    
    func togglePreview() {
        if let selected = yippyHistoryView.selected {
            isPreviewShowing = !isPreviewShowing
            if isPreviewShowing {
                State.main.previewHistoryItem.accept(yippyHistory.items[selected])
            }
            else {
                State.main.previewHistoryItem.accept(nil)
            }
        }
    }
    
    func focusSearchBar() {
        NSApp.activate(ignoringOtherApps: true)
        self.searchBar.becomeFirstResponder()
    }
    
    func runSearch() {
        let isFiltered = self.isFiltered
        searchEngine.search(query: searchBar.stringValue, filter: filter.value, items: State.main.history.items) { items in
            self.results.accept(Results(items: items, isSearchResult: isFiltered))
            if self.selected.value == nil || self.selected.value! >= items.count {
                self.resetSelected()
            }
        }
    }
    
    private func incrementSelected() {
        guard let s = selected.value else {
            if yippyHistory.items.count > 0 {
                selected.accept(0)
            }
            return
        }
        if s < yippyHistory.items.count - 1 {
            selected.accept(s + 1)
        }
    }
    
    private func decrementSelected() {
        guard let s = selected.value else {
            if yippyHistory.items.count > 0 {
                selected.accept(0)
            }
            return
        }
        if s > 0 {
            selected.accept(s - 1)
        }
    }
    
    private func paste(selected: Int, asPlainText: Bool = false) {
        guard selected < yippyHistory.items.count else { return }
        let yippyHistory = self.yippyHistory
        self.close()
        yippyHistory.paste(selected: selected, asPlainText: asPlainText)
    }
}

extension YippyViewController: NSMenuDelegate {
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let row = yippyHistoryView.clickedRow
        guard row >= 0, row < yippyHistory.items.count else { return }
        let item = yippyHistory.items[row]
        
        menu.addItem(menuItem("Paste", symbol: "doc.on.clipboard", action: .paste))
        if YippyHistory.plainText(for: item) != nil {
            menu.addItem(menuItem(item.kind == .image ? "Paste Recognized Text" : "Paste as Plain Text", symbol: "textformat", action: .pastePlainText))
        }
        menu.addItem(menuItem(item.metadata.isPinned ? "Unpin" : "Pin", symbol: item.metadata.isPinned ? "pin.slash" : "pin", action: .togglePin))
        menu.addItem(menuItem("Preview", symbol: "eye", action: .preview))
        if let text = item.metadata.recognizedText, !text.isEmpty {
            menu.addItem(menuItem("Copy Recognized Text", symbol: "text.viewfinder", action: .copyRecognizedText))
        }
        if item.kind == .link {
            menu.addItem(menuItem("Open Link", symbol: "safari", action: .openLink))
        }
        if item.kind == .file {
            menu.addItem(menuItem("Show in Finder", symbol: "folder", action: .revealInFinder))
        }
        menu.addItem(.separator())
        menu.addItem(menuItem("Delete", symbol: "trash", action: .delete))
    }
}

extension YippyViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        runSearch()
    }
}

extension YippyViewController: YippyTableViewDelegate {
    func yippyTableView(_ yippyTableView: YippyTableView, selectedDidChange selected: Int?) {
        self.selected.accept(selected)
    }
    
    func yippyTableView(_ yippyTableView: YippyTableView, didMoveItem from: Int, to: Int) {
        yippyHistory.move(from: from, to: to)
        selected.accept(to)
    }
}
