//
//  MagpieViewController.swift
//  Magpie
//

import Cocoa
import HotKey

struct Results {
    let items: [HistoryItem]
    let isSearchResult: Bool
}

class MagpieViewController: NSViewController {
    
    @IBOutlet var magpieHistoryView: MagpieTableView!
    
    @IBOutlet var itemGroupScrollView: HorizontalButtonsView!
    @IBOutlet var itemCountLabel: NSTextField!
    
    @IBOutlet var searchBar: NSTextField!
    
    var magpieHistory = MagpieHistory(history: AppState.main.history, items: [])
    
    let searchEngine = SearchEngine()
    
    var filter = HistoryFilter.all {
        didSet {
            guard filter != oldValue else { return }
            updateFilterChips()
            runSearch()
        }
    }
    
    var isPreviewShowing = false
    
    var isRichText = Settings.main.showsRichText
    
    /// The items to show. Setting it updates the table.
    var results = Results(items: [], isSearchResult: false) {
        didSet { render(previousSelection: selected) }
    }
    
    /// The selected row in `results`. Setting it updates the table.
    var selected: Int? {
        didSet {
            guard selected != oldValue else { return }
            render(previousSelection: oldValue)
        }
    }
    
    /// Hotkeys that only act while the panel is shown.
    private var panelHotKeys = [MagpieHotKey]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        magpieHistoryView.magpieDelegate = self
        
        AppState.main.history.subscribe(onNext: onHistoryChange)
        
        Magpie.observe({ AppState.main.showsRichText }, onChange: onShowsRichText)
        
        styleHeader()
        itemGroupScrollView.symbolNames = HistoryFilter.chips.map({ $0.symbolName }) + ["tag"]
        itemGroupScrollView.innerPadding = 4
        itemGroupScrollView.leftPadding = 12
        itemGroupScrollView.rightPadding = 12
        itemGroupScrollView.setTitles(HistoryFilter.chips.map({ $0.title }) + ["Tags"])
        updateFilterChips()
        itemGroupScrollView.onSelect = { [weak self] in
            guard let self = self else { return }
            if $0 < HistoryFilter.chips.count {
                self.filter = HistoryFilter.chips[$0]
            }
            else {
                self.showTagsMenu()
            }
        }
        
        magpieHistoryView.menu = makeContextMenu()
        
        searchBar.delegate = self
        
        render(previousSelection: nil)
        resetSelected()
        
        MagpieHotKeys.downArrow.onDown(goToNextItem)
        MagpieHotKeys.downArrow.onLong(goToNextItem)
        MagpieHotKeys.pageDown.onDown(goToNextItem)
        MagpieHotKeys.pageDown.onLong(goToNextItem)
        MagpieHotKeys.upArrow.onDown(goToPreviousItem)
        MagpieHotKeys.upArrow.onLong(goToPreviousItem)
        MagpieHotKeys.pageUp.onDown(goToPreviousItem)
        MagpieHotKeys.pageUp.onLong(goToPreviousItem)
        MagpieHotKeys.escape.onDown(close)
        MagpieHotKeys.return.onDown(pasteSelected)
        MagpieHotKeys.ctrlAltCmdLeftArrow.onDown { AppState.main.panelPosition = .left }
        MagpieHotKeys.ctrlAltCmdRightArrow.onDown { AppState.main.panelPosition = .right }
        MagpieHotKeys.ctrlAltCmdDownArrow.onDown { AppState.main.panelPosition = .bottom }
        MagpieHotKeys.ctrlAltCmdUpArrow.onDown { AppState.main.panelPosition = .top }
        MagpieHotKeys.ctrlDelete.onDown(deleteSelected)
        MagpieHotKeys.ctrlSpace.onDown(togglePreview)
        MagpieHotKeys.cmdBackslash.onDown(focusSearchBar)
        MagpieHotKeys.optionReturn.onDown(pasteSelectedAsPlainText)
        MagpieHotKeys.cmdP.onDown(togglePinSelected)
        MagpieHotKeys.cmdLeftArrow.onDown { self.cycleFilter(by: -1) }
        MagpieHotKeys.cmdRightArrow.onDown { self.cycleFilter(by: 1) }
        
        // Paste hot keys
        MagpieHotKeys.cmd0.onDown { self.shortcutPressed(key: 0) }
        MagpieHotKeys.cmd1.onDown { self.shortcutPressed(key: 1) }
        MagpieHotKeys.cmd2.onDown { self.shortcutPressed(key: 2) }
        MagpieHotKeys.cmd3.onDown { self.shortcutPressed(key: 3) }
        MagpieHotKeys.cmd4.onDown { self.shortcutPressed(key: 4) }
        MagpieHotKeys.cmd5.onDown { self.shortcutPressed(key: 5) }
        MagpieHotKeys.cmd6.onDown { self.shortcutPressed(key: 6) }
        MagpieHotKeys.cmd7.onDown { self.shortcutPressed(key: 7) }
        MagpieHotKeys.cmd8.onDown { self.shortcutPressed(key: 8) }
        MagpieHotKeys.cmd9.onDown { self.shortcutPressed(key: 9) }
        
        panelHotKeys.append(MagpieHotKeys.downArrow)
        panelHotKeys.append(MagpieHotKeys.upArrow)
        panelHotKeys.append(MagpieHotKeys.return)
        panelHotKeys.append(MagpieHotKeys.escape)
        panelHotKeys.append(MagpieHotKeys.pageDown)
        panelHotKeys.append(MagpieHotKeys.pageUp)
        panelHotKeys.append(MagpieHotKeys.ctrlAltCmdLeftArrow)
        panelHotKeys.append(MagpieHotKeys.ctrlAltCmdRightArrow)
        panelHotKeys.append(MagpieHotKeys.ctrlAltCmdDownArrow)
        panelHotKeys.append(MagpieHotKeys.ctrlAltCmdUpArrow)
        panelHotKeys.append(MagpieHotKeys.cmd0)
        panelHotKeys.append(MagpieHotKeys.cmd1)
        panelHotKeys.append(MagpieHotKeys.cmd2)
        panelHotKeys.append(MagpieHotKeys.cmd3)
        panelHotKeys.append(MagpieHotKeys.cmd4)
        panelHotKeys.append(MagpieHotKeys.cmd5)
        panelHotKeys.append(MagpieHotKeys.cmd6)
        panelHotKeys.append(MagpieHotKeys.cmd7)
        panelHotKeys.append(MagpieHotKeys.cmd8)
        panelHotKeys.append(MagpieHotKeys.cmd9)
        panelHotKeys.append(MagpieHotKeys.ctrlDelete)
        panelHotKeys.append(MagpieHotKeys.ctrlSpace)
        panelHotKeys.append(MagpieHotKeys.optionReturn)
        panelHotKeys.append(MagpieHotKeys.cmdP)
        panelHotKeys.append(MagpieHotKeys.cmdLeftArrow)
        panelHotKeys.append(MagpieHotKeys.cmdRightArrow)
        
        Magpie.observe({ AppState.main.isHistoryPanelShown }) { [weak self] isShown in
            self?.panelHotKeys.forEach({ $0.isPaused = !isShown })
        }
        
        searchBar.resignFirstResponder()
    }
    
    private func styleHeader() {
        if let title = view.subviews.compactMap({ $0 as? NSTextField }).first(where: { $0.stringValue == "Magpie" }) {
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
        magpieHistoryView.redisplayVisible(magpieItems: magpieHistory.items)
        
        isPreviewShowing = false
        resetSelected()
    }
    
    func resetSelected() {
        if magpieHistory.items.count > 0 {
            selected = 0
        }
        else {
            selected = nil
        }
    }
    
    var isFiltered: Bool {
        return !searchBar.stringValue.trimmingCharacters(in: .whitespaces).isEmpty || filter != .all
    }
    
    func onHistoryChange(_ history: [HistoryItem], change: History.Change) {
        if case .update(let i) = change {
            // Metadata changed; the item may now be in or out of the filter (e.g. unpinned while viewing Pinned).
            if isFiltered {
                runSearch()
            }
            if let row = magpieHistory.items.firstIndex(of: history[i]) {
                magpieHistoryView.reloadItem(row)
            }
            return
        }
        if isFiltered {
            runSearch()
        }
        else {
            results = Results(items: history, isSearchResult: false)
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
    
    /// Updates the table for the current `results` and `selected` row, deselecting `previousSelection`.
    func render(previousSelection: Int?) {
        let results = self.results
        let selected = (previousSelection, self.selected)
        if results.items != self.magpieHistory.items {
                if results.isSearchResult {
                    self.itemCountLabel.stringValue = "\(results.items.count) \(results.items.count == 1 ? "match" : "matches")"
                }
                else {
                    self.itemCountLabel.stringValue = "\(results.items.count) items"
                }
                
                self.magpieHistory = MagpieHistory(history: AppState.main.history, items: results.items)
                self.magpieHistoryView.allowsReordering = !results.isSearchResult
                self.magpieHistoryView.reloadData(self.magpieHistory.items, isRichText: self.isRichText)
            }
        
        if let previous = selected.0 {
            self.magpieHistoryView.deselectItem(previous)
            self.magpieHistoryView.reloadItem(previous)
        }
        if let selected = selected.1, selected < self.magpieHistory.items.count {
            let currentSelection = self.magpieHistoryView.selected
            if currentSelection == nil || currentSelection != selected {
                self.magpieHistoryView.selectItem(selected)
            }
            self.magpieHistoryView.reloadItem(selected)
            
            if self.isPreviewShowing && selected < self.magpieHistory.items.count {
                AppState.main.previewHistoryItem = self.magpieHistory.items[selected]
            }
        }
    }
    
    func onShowsRichText(_ showsRichText: Bool) {
        isRichText = showsRichText
        magpieHistoryView.reloadData(magpieHistory.items, isRichText: isRichText)
    }
    
    func goToNextItem() {
        incrementSelected()
    }
    
    func goToPreviousItem() {
        decrementSelected()
    }
    
    func pasteSelected() {
        if let selected = self.magpieHistoryView.selected {
            paste(selected: selected)
        }
    }
    
    func pasteSelectedAsPlainText() {
        if let selected = self.magpieHistoryView.selected {
            paste(selected: selected, asPlainText: true)
        }
    }
    
    func togglePinSelected() {
        if let selected = self.magpieHistoryView.selected {
            magpieHistory.togglePin(selected: selected)
        }
    }
    
    func cycleFilter(by offset: Int) {
        let chips = HistoryFilter.chips
        let current = chips.firstIndex(of: filter) ?? 0
        filter = chips[(current + offset + chips.count) % chips.count]
    }
    
    /// Highlights the chip for the current filter. A tag filter highlights the Tags chip, titled with the tag.
    private func updateFilterChips() {
        let tagsIndex = HistoryFilter.chips.count
        if case .tag(let tag) = filter {
            itemGroupScrollView.setTitle(tag, at: tagsIndex)
            itemGroupScrollView.select(tagsIndex)
        }
        else {
            itemGroupScrollView.setTitle("Tags", at: tagsIndex)
            itemGroupScrollView.select(HistoryFilter.chips.firstIndex(of: filter) ?? 0)
        }
    }
    
    /// Lists the tags found in the history, with counts, below the Tags chip.
    private func showTagsMenu() {
        let menu = NSMenu()
        let tags = HistoryFilter.tags(in: AppState.main.history.items)
        if tags.isEmpty {
            let item = NSMenuItem(title: "No tags yet", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
            menu.addItem(NSMenuItem(title: "Code languages, emails, phone numbers and addresses are tagged automatically.", action: nil, keyEquivalent: ""))
            menu.items.last?.isEnabled = false
        }
        for (tag, count) in tags {
            let item = NSMenuItem(title: "\(tag)  \(count)", action: #selector(tagSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = tag
            item.state = filter == .tag(tag) ? .on : .off
            menu.addItem(item)
        }
        if case .tag = filter {
            menu.addItem(.separator())
            let clear = NSMenuItem(title: "Show All", action: #selector(tagSelected(_:)), keyEquivalent: "")
            clear.target = self
            menu.addItem(clear)
        }
        if let chip = itemGroupScrollView.button(at: HistoryFilter.chips.count) {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: chip.bounds.maxY + 4), in: chip)
        }
        updateFilterChips()
    }
    
    @objc private func tagSelected(_ sender: NSMenuItem) {
        filter = (sender.representedObject as? String).map({ .tag($0) }) ?? .all
    }
    
    func deleteSelected() {
        if let selected = self.magpieHistoryView.selected {
            self.selected = magpieHistory.delete(selected: selected)
        }
    }
    
    func close() {
        isPreviewShowing = false
        AppState.main.isHistoryPanelShown = false
        AppState.main.previewHistoryItem = nil
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
        let row = magpieHistoryView.clickedRow
        guard row >= 0, row < magpieHistory.items.count, let action = MenuAction(rawValue: sender.tag) else { return }
        let item = magpieHistory.items[row]
        switch action {
        case .paste:
            paste(selected: row)
        case .pastePlainText:
            paste(selected: row, asPlainText: true)
        case .togglePin:
            magpieHistory.togglePin(selected: row)
        case .preview:
            selected = row
            isPreviewShowing = true
            AppState.main.previewHistoryItem = item
        case .copyRecognizedText:
            guard let text = item.recognizedText else { return }
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
            let next = magpieHistory.delete(selected: row)
            if !isFiltered {
                selected = next
            }
        }
    }
    
    func togglePreview() {
        if let selected = magpieHistoryView.selected {
            isPreviewShowing = !isPreviewShowing
            if isPreviewShowing {
                AppState.main.previewHistoryItem = magpieHistory.items[selected]
            }
            else {
                AppState.main.previewHistoryItem = nil
            }
        }
    }
    
    func focusSearchBar() {
        NSApp.activate(ignoringOtherApps: true)
        self.searchBar.becomeFirstResponder()
    }
    
    func runSearch() {
        let isFiltered = self.isFiltered
        searchEngine.search(query: searchBar.stringValue, filter: filter, items: AppState.main.history.items) { items in
            self.results = Results(items: items, isSearchResult: isFiltered)
            if self.selected == nil || self.selected! >= items.count {
                self.resetSelected()
            }
        }
    }
    
    private func incrementSelected() {
        guard let s = selected else {
            if magpieHistory.items.count > 0 {
                selected = 0
            }
            return
        }
        if s < magpieHistory.items.count - 1 {
            selected = s + 1
        }
    }
    
    private func decrementSelected() {
        guard let s = selected else {
            if magpieHistory.items.count > 0 {
                selected = 0
            }
            return
        }
        if s > 0 {
            selected = s - 1
        }
    }
    
    private func paste(selected: Int, asPlainText: Bool = false) {
        guard selected < magpieHistory.items.count else { return }
        let magpieHistory = self.magpieHistory
        self.close()
        magpieHistory.paste(selected: selected, asPlainText: asPlainText)
    }
}

extension MagpieViewController: NSMenuDelegate {
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let row = magpieHistoryView.clickedRow
        guard row >= 0, row < magpieHistory.items.count else { return }
        let item = magpieHistory.items[row]
        
        menu.addItem(menuItem("Paste", symbol: "doc.on.clipboard", action: .paste))
        if MagpieHistory.plainText(for: item) != nil {
            menu.addItem(menuItem(item.kind == .image ? "Paste Recognized Text" : "Paste as Plain Text", symbol: "textformat", action: .pastePlainText))
        }
        menu.addItem(menuItem(item.isPinned ? "Unpin" : "Pin", symbol: item.isPinned ? "pin.slash" : "pin", action: .togglePin))
        menu.addItem(menuItem("Preview", symbol: "eye", action: .preview))
        if let text = item.recognizedText, !text.isEmpty {
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

extension MagpieViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        runSearch()
    }
}

extension MagpieViewController: MagpieTableViewDelegate {
    func magpieTableView(_ magpieTableView: MagpieTableView, selectedDidChange selected: Int?) {
        self.selected = selected
    }
    
    func magpieTableView(_ magpieTableView: MagpieTableView, didMoveItem from: Int, to: Int) {
        magpieHistory.move(from: from, to: to)
        selected = to
    }
}
