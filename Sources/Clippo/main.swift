import AppKit
import Carbon
import ServiceManagement
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = Store.shared
    private let monitor = ClipboardMonitor()
    private let queue = PasteQueue()
    private let historyModel = HistoryModel()
    private let listModel = ListModel()

    private var historyPanel: FloatingPanel!
    private var listPanel: FloatingPanel!
    private var queuePanel: FloatingPanel!
    private var statusItem: NSStatusItem!
    private var hotKeys: [HotKey] = []
    private var pasteNextKey: HotKey!
    private var awaitingSplit = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        if Demo.isOn { startDemo(); return }
        if AppMover.offerMoveIfNeeded() { return }
        buildPanels()

        monitor.onCopy = { [weak self] in self?.handleCopy($0) }
        monitor.onCopyImage = { [weak self] in self?.store.recordImage($0) }
        monitor.start()

        registerShortcuts()
        Settings.shared.onEncryptionChange = { [weak self] in self?.queue.rewrite() }
        Settings.shared.onShortcutsChange = { [weak self] in self?.registerShortcuts() }
        Settings.shared.onRecording = { [weak self] on in self?.hotKeys.forEach { $0.setEnabled(!on) } }
        // ⌘V is only hijacked while the queue has something to paste; otherwise it stays the normal paste.
        pasteNextKey = HotKey(keyCode: kVK_ANSI_V, modifiers: cmdKey, enabled: false) { [weak self] in
            self?.pasteNextFromQueue()
        }
        queue.onChange = { [weak self] in self?.queueChanged() }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKey(event) ?? event
        }

        setupStatusItem()
        Updater.shared.start()
        let granted = Paster.ensureAccessibility(prompt: false)
        UserDefaults.standard.set(granted, forKey: "accessibilityGranted")
        if !granted || !UserDefaults.standard.bool(forKey: "onboarded") { showOnboarding() }
    }

    private var keyMonitor: Any?

    private func startDemo() {
        buildPanels()
        let icon = NSApp.applicationIconImage.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:))?
            .representation(using: .png, properties: [:])
        store.seedDemo(image: icon)
        queue.activate()
        queue.push(Demo.queue)
        _ = queue.popNext(); _ = queue.popNext()
        setupStatusItem()
        NSApp.activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.showDemoPanel() }
    }

    private func showDemoPanel() {
        switch Demo.panel {
        case "list": toggleList()
        case "queue": queuePanel.present()
        case "settings": openSettings()
        case "onboarding": showOnboarding()
        default: toggleHistory()
        }
    }
    private var settingsWindow: NSWindow?

    private func registerShortcuts() {
        hotKeys.forEach { $0.setEnabled(false) }
        UserDefaults.standard.removeObject(forKey: "hotkeyFailures")
        hotKeys = ShortcutAction.allCases.map { action in
            let s = Settings.shared.shortcut(action)
            return HotKey(keyCode: s.keyCode, modifiers: s.modifiers) { [weak self] in self?.perform(action) }
        }
    }

    private func perform(_ action: ShortcutAction) {
        switch action {
        case .history: toggleHistory()
        case .list: toggleList()
        case .queue: toggleQueue()
        case .clearQueue: queue.clear()
        case .copyLines: copyAsLines()
        }
    }

    /// Launching Clippo again (Spotlight, /Applications) opens settings — there is no Dock icon to click.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return false
    }

    private var onboardingWindow: NSWindow?

    @objc private func showOnboarding() {
        if onboardingWindow == nil {
            let view = OnboardingView { [weak self] in
                UserDefaults.standard.set(true, forKey: "onboarded")
                self?.onboardingWindow?.close()
            }
            let w = NSWindow(contentViewController: NSHostingController(rootView: view))
            w.title = "Clippo"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            onboardingWindow = w
        }
        NSApp.activate()
        onboardingWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            w.title = L("Настройки Clippo")
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            settingsWindow = w
        }
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }


    /// Panel shortcuts handled at the window level so they work regardless of SwiftUI focus.
    private func handleKey(_ event: NSEvent) -> NSEvent? {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            .subtracting([.capsLock, .numericPad, .function])
        // By physical key so it works in any layout and with ⌘ still held from ⌘I.
        let digit = Self.digitKeys[Int(event.keyCode)]

        if listPanel.isKeyWindow, listModel.draft == .none {
            let items = listModel.list(in: store)?.items ?? []
            if let n = digit, mods.isSubset(of: .command) {
                let idx = n == 0 ? 9 : n - 1
                if items.indices.contains(idx) { let t = items[idx].text; DispatchQueue.main.async { self.pickFromList(t) } }
                return nil
            }
            if mods == .command, Int(event.keyCode) == kVK_ANSI_N { listModel.beginAdd(); return nil }
            switch Int(event.keyCode) {
            case kVK_Escape: DispatchQueue.main.async { self.listPanel.orderOut(nil) }; return nil
            case kVK_DownArrow: listModel.selection = min(max(items.count - 1, 0), listModel.selection + 1); return nil
            case kVK_UpArrow: listModel.selection = max(0, listModel.selection - 1); return nil
            case kVK_Return, kVK_ANSI_KeypadEnter:
                if items.indices.contains(listModel.selection) { let t = items[listModel.selection].text; DispatchQueue.main.async { self.pickFromList(t) } }
                return nil
            default: break
            }
        }

        return event
    }

    private static let digitKeys: [Int: Int] = [
        kVK_ANSI_1: 1, kVK_ANSI_2: 2, kVK_ANSI_3: 3, kVK_ANSI_4: 4, kVK_ANSI_5: 5,
        kVK_ANSI_6: 6, kVK_ANSI_7: 7, kVK_ANSI_8: 8, kVK_ANSI_9: 9, kVK_ANSI_0: 0,
        kVK_ANSI_Keypad1: 1, kVK_ANSI_Keypad2: 2, kVK_ANSI_Keypad3: 3, kVK_ANSI_Keypad4: 4, kVK_ANSI_Keypad5: 5,
        kVK_ANSI_Keypad6: 6, kVK_ANSI_Keypad7: 7, kVK_ANSI_Keypad8: 8, kVK_ANSI_Keypad9: 9, kVK_ANSI_Keypad0: 0,
    ]

    private func pickFromList(_ text: String) {
        listPanel.orderOut(nil)
        paste(text)
    }

    private func pickFromHistory(_ clip: Clip) {
        historyPanel.orderOut(nil)
        store.bump(clip)
        if let name = clip.image {
            guard let png = ImageStore.load(name) else { NSSound.beep(); return }
            paste { Paster.write(image: png) }
        } else {
            paste(clip.text)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.flush()
        if Settings.shared.clearOnQuit { queue.clear() } // the queue holds copied text too
        queue.flush()
    }

    private func buildPanels() {
        historyPanel = FloatingPanel(
            name: "Clippo.History", size: NSSize(width: 600, height: 480), minSize: NSSize(width: 420, height: 280),
            takesKey: true, closesOnResign: true,
            content: HistoryView(store: store, model: historyModel,
                                 onPick: { [weak self] in self?.pickFromHistory($0) },
                                 onClose: { [weak self] in self?.historyPanel.orderOut(nil) }))

        listPanel = FloatingPanel(
            name: "Clippo.List", size: NSSize(width: 360, height: 400), minSize: NSSize(width: 280, height: 220),
            takesKey: true, closesOnResign: true,
            content: ListView(store: store, model: listModel,
                              onPick: { [weak self] in self?.pickFromList($0) },
                              onClose: { [weak self] in self?.listPanel.orderOut(nil) }))

        queuePanel = FloatingPanel(
            name: "Clippo.Queue", size: NSSize(width: 320, height: 380), minSize: NSSize(width: 260, height: 200),
            takesKey: false, closesOnResign: false,
            content: QueueView(queue: queue, onHide: { [weak self] in self?.queue.deactivate() }))
        queuePanel.animationBehavior = .none
    }

    // MARK: Copy

    private func handleCopy(_ text: String) {
        store.record(text)
        if awaitingSplit {
            NSLog("Clippo split#%d: got copy, %d lines", splitToken, ClipText.lines(text).count)
            awaitingSplit = false
            if !queue.isActive { queue.activate() }
            queue.push(ClipText.lines(text))
        } else {
            queue.push([text])
        }
    }

    /// ⇧⌘C: copies the selection, then queues each non-empty line separately (a column → N pastes).
    private func copyAsLines() {
        guard Paster.ensureAccessibility(prompt: false) else { NSSound.beep(); return }
        splitToken += 1
        let token = splitToken
        NSLog("Clippo split#%d: hotkey, front=%@", token, NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "?")
        awaitingSplit = true
        // The hotkey fires on key-down. A synthetic ⌘C sent while the real C (or Shift) is still held is
        // read as auto-repeat or as ⇧⌘C (Chrome's Inspect) and silently ignored — wait for both to go up.
        whenKeysReleased { [weak self] in
            guard let self, token == self.splitToken else { return }
            let before = NSPasteboard.general.changeCount
            NSLog("Clippo split#%d: keys up, send ⌘C, cc=%d front=%@", token, before, NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "?")
            Paster.sendCommandC()
            // Slow apps sometimes drop the first one; try once more if nothing reached the pasteboard.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, token == self.splitToken, self.awaitingSplit,
                      NSPasteboard.general.changeCount == before else { return }
                NSLog("Clippo split#%d: no change, retry ⌘C", token)
                Paster.sendCommandC()
            }
            // Nothing selected → no pasteboard change; don't let the flag swallow a later normal copy.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if token == self?.splitToken, self?.awaitingSplit == true {
                    NSLog("Clippo split#%d: gave up, nothing copied", token)
                    self?.awaitingSplit = false
                }
            }
        }
    }

    private var splitToken = 0

    private func whenKeysReleased(waited: Double = 0, _ action: @escaping () -> Void) {
        let held = CGEventSource.keyState(.hidSystemState, key: CGKeyCode(kVK_Shift))
            || CGEventSource.keyState(.hidSystemState, key: CGKeyCode(kVK_RightShift))
            || CGEventSource.keyState(.hidSystemState, key: CGKeyCode(Settings.shared.shortcut(.copyLines).keyCode))
        if !held || waited >= 1.5 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: action); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.015) { [weak self] in
            self?.whenKeysReleased(waited: waited + 0.015, action)
        }
    }

    // MARK: Paste

    private func pasteNextFromQueue() {
        guard let text = queue.popNext() else { return }
        paste(text)
    }

    private func paste(_ text: String) {
        paste { Paster.write(text) }
    }

    private func paste(writing write: () -> Void) {
        write()
        monitor.ignoreCurrentChange()
        guard Paster.ensureAccessibility(prompt: false) else {
            NSLog("Clippo: paste blocked — no Accessibility permission (text left on clipboard)")
            NSSound.beep()
            DispatchQueue.main.async { self.showOnboarding() }
            return
        }
        // Our synthetic ⌘V must not re-trigger the queue hotkey.
        pasteNextKey.setEnabled(false)
        // macOS makes Clippo the active app while a panel is key; a ⌘V sent then lands in Clippo (no window → beep).
        // Hand focus back to where the user was and wait until it's really frontmost.
        let front = NSWorkspace.shared.frontmostApplication
        let target = (front != nil && front != .current) ? front : targetApp
        if NSApp.isActive {
            NSApp.deactivate()
            target?.activate()
        }
        whenTargetIsFrontmost { [weak self] in
            Paster.sendCommandV(to: target)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.pasteNextKey.setEnabled(self?.queue.hasPending ?? false)
            }
        }
    }

    /// App the user was in when a panel was opened; pastes go back there.
    private var targetApp: NSRunningApplication?

    private func rememberTargetApp() {
        if let front = NSWorkspace.shared.frontmostApplication, front != .current { targetApp = front }
    }

    private func whenTargetIsFrontmost(waited: Double = 0, _ action: @escaping () -> Void) {
        if !NSApp.isActive || waited >= 0.6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: action)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            self?.whenTargetIsFrontmost(waited: waited + 0.02, action)
        }
    }

    // MARK: Panels

    private func toggleHistory() {
        if historyPanel.isVisible { historyPanel.orderOut(nil); return }
        historyModel.query = ""
        historyModel.tab = nil
        historyModel.selection = 0
        rememberTargetApp()
        historyPanel.present()
        historyModel.focusToken += 1
    }

    private func toggleList() {
        if listPanel.isVisible { listPanel.orderOut(nil); return }
        if !store.lists.contains(where: { $0.id == listModel.listID }) {
            listModel.listID = store.lists.first?.id
        }
        listModel.draft = .none
        listModel.draftText = ""
        listModel.selection = 0
        rememberTargetApp()
        listPanel.present()
        listModel.focusToken += 1
    }

    private func toggleQueue() {
        queue.isActive ? queue.deactivate() : queue.activate()
    }

    private func queueChanged() {
        pasteNextKey.setEnabled(queue.hasPending)
        statusItem?.button?.title = queue.isActive ? " \(queue.items.count)" : ""
        if queue.isActive, !queuePanel.isVisible {
            queuePanel.present()
        } else if !queue.isActive, queuePanel.isVisible {
            queuePanel.orderOut(nil)
        }
    }

    // MARK: Menu bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clippo")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.imagePosition = .imageLeading
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let s = Settings.shared
        add(menu, L("История"), s.shortcut(.history).label, #selector(menuHistory))
        add(menu, L("Списки"), s.shortcut(.list).label, #selector(menuList))
        add(menu, queue.isActive ? L("Paste Queue — выключить") : L("Paste Queue — включить"), s.shortcut(.queue).label, #selector(menuQueue))
        menu.addItem(.separator())
        if IsSecureEventInputEnabled() {
            // macOS blocks every app's global shortcuts while a password field (or a buggy app) holds Secure Input.
            let item = add(menu, L("⚠️ Secure Input включён — сочетания не работают"), nil, #selector(noop))
            item.toolTip = L("Пока активно поле пароля, macOS блокирует горячие клавиши всех программ. Переключитесь в другую программу; если не помогло — перезапустите менеджер паролей.")
            menu.addItem(.separator())
        }
        if !Paster.ensureAccessibility(prompt: false) {
            add(menu, L("⚠️ Нет доступа: Универсальный доступ…"), nil, #selector(showOnboarding))
            menu.addItem(.separator())
        }
        if let update = Updater.shared.available {
            add(menu, String(format: L("⬇︎ Доступна версия %@ — скачать"), update.version), nil, #selector(openUpdate))
            menu.addItem(.separator())
        }
        add(menu, L("Настройки…"), "⌘,", #selector(openSettings))
        add(menu, L("Показать файл данных"), nil, #selector(revealData))
        menu.addItem(.separator())
        add(menu, L("Выйти из Clippo"), nil, #selector(quit))
    }

    @discardableResult
    private func add(_ menu: NSMenu, _ title: String, _ shortcut: String?, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        if let shortcut {
            let attr = NSMutableAttributedString(string: title + "  ")
            attr.append(NSAttributedString(string: shortcut, attributes: [.foregroundColor: NSColor.secondaryLabelColor]))
            item.attributedTitle = attr
        }
        menu.addItem(item)
        return item
    }

    @objc private func menuHistory() { toggleHistory() }
    @objc private func menuList() { toggleList() }
    @objc private func menuQueue() { toggleQueue() }
    @objc private func revealData() { NSWorkspace.shared.activateFileViewerSelecting([store.fileURL]) }
    @objc private func noop() {}
    @objc private func openUpdate() { Updater.shared.available.map { NSWorkspace.shared.open($0.url) } }
    @objc private func quit() { NSApp.terminate(nil) }

}

Demo.prepare()
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

