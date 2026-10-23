import AppKit

/// Run from Downloads, macOS launches a read-only randomized copy (App Translocation): login items and the
/// Accessibility grant then point at a path that disappears. Offer to move into /Applications first.
enum AppMover {
    /// Returns true when the app is about to relaunch or quit, so launch should stop.
    static func offerMoveIfNeeded() -> Bool {
        let path = Bundle.main.bundlePath
        let apps = ["/Applications/", NSHomeDirectory() + "/Applications/"]
        guard !apps.contains(where: path.hasPrefix) else { return false }
        let translocated = path.contains("/AppTranslocation/")

        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = L("Переместить Clippo в «Программы»?")
        alert.informativeText = translocated
            ? L("Clippo запущен прямо из загрузок. Перетащите его в папку «Программы» и откройте оттуда, иначе автозапуск и Универсальный доступ не будут работать.")
            : L("Иначе автозапуск и Универсальный доступ могут перестать работать.")
        if translocated {
            alert.addButton(withTitle: L("Выйти"))
            alert.addButton(withTitle: L("Всё равно продолжить"))
            if alert.runModal() == .alertFirstButtonReturn { NSApp.terminate(nil); return true }
            return false
        }
        alert.addButton(withTitle: L("Переместить"))
        alert.addButton(withTitle: L("Не сейчас"))
        guard alert.runModal() == .alertFirstButtonReturn else { return false }

        let dest = URL(fileURLWithPath: "/Applications/Clippo.app")
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: dest.path) { try fm.trashItem(at: dest, resultingItemURL: nil) }
            try fm.copyItem(at: Bundle.main.bundleURL, to: dest)
        } catch {
            let fail = NSAlert(error: error)
            fail.runModal()
            return false
        }
        try? fm.trashItem(at: Bundle.main.bundleURL, resultingItemURL: nil)
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: dest, configuration: config) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
        return true
    }
}
