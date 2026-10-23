import AppKit
import ApplicationServices

enum Paster {
    @discardableResult
    static func ensureAccessibility(prompt: Bool) -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    static func write(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    static func write(image png: Data) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setData(png, forType: .png)
        // Some apps only take TIFF.
        if let tiff = NSImage(data: png)?.tiffRepresentation { pb.setData(tiff, forType: .tiff) }
    }

    /// With a target, ⌘V is delivered straight to that process: right after a Clippo panel closes, the
    /// WindowServer still routes keys to Clippo, which has no window to handle them and beeps.
    static func sendCommandV(to target: NSRunningApplication? = nil) { sendCommand(9, to: target) }
    static func sendCommandC() { sendCommand(8, to: nil) }

    private static func sendCommand(_ key: CGKeyCode, to target: NSRunningApplication?) {
        // Private state: the real keyboard's modifiers (a still-held Shift) are not merged into our event.
        let src = CGEventSource(stateID: .privateState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: key, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        if let pid = target?.processIdentifier, pid > 0 {
            down?.postToPid(pid)
            up?.postToPid(pid)
        } else {
            down?.post(tap: .cghidEventTap)
            up?.post(tap: .cghidEventTap)
        }
    }
}
