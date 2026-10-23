import AppKit

/// The menu bar icon: Clippo's long hair, blunt bangs and shirt collar as a one-color template image,
/// so macOS tints it for light and dark menu bars like any system icon.
enum MenuBarIcon {
    static func make(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: true) { rect in
            let s = rect.width / 20
            func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * s, y: y * s) }
            func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect { NSRect(x: x * s, y: y * s, width: w * s, height: h * s) }
            NSColor.black.setFill()

            // Long hair.
            let hair = NSBezierPath()
            hair.move(to: p(3.4, 15.8))
            hair.curve(to: p(10, 0.8), controlPoint1: p(2.6, 9), controlPoint2: p(3.6, 1.2))
            hair.curve(to: p(16.6, 15.8), controlPoint1: p(16.4, 1.2), controlPoint2: p(17.4, 9))
            hair.close()
            hair.fill()

            // Shoulders.
            let body = NSBezierPath()
            body.move(to: p(2.2, 20))
            body.curve(to: p(7.4, 15.6), controlPoint1: p(2.4, 17.4), controlPoint2: p(4.6, 15.9))
            body.line(to: p(12.6, 15.6))
            body.curve(to: p(17.8, 20), controlPoint1: p(15.4, 15.9), controlPoint2: p(17.6, 17.4))
            body.close()
            body.fill()

            // Face, neck and the V of the collar are cut out of the dark shape.
            NSGraphicsContext.current?.compositingOperation = .clear
            NSBezierPath(ovalIn: r(6.0, 4.4, 8.0, 9.6)).fill()
            NSBezierPath(rect: r(8.7, 12.5, 2.6, 3.4)).fill()
            let collar = NSBezierPath()
            collar.move(to: p(8.0, 15.4))
            collar.line(to: p(12.0, 15.4))
            collar.line(to: p(10, 18.6))
            collar.close()
            collar.fill()
            NSGraphicsContext.current?.compositingOperation = .sourceOver

            // Blunt bangs and two calm eyes.
            let bangs = NSBezierPath()
            bangs.move(to: p(5.9, 8.0))
            bangs.curve(to: p(10, 3.6), controlPoint1: p(5.8, 5.4), controlPoint2: p(7.6, 3.6))
            bangs.curve(to: p(14.1, 8.0), controlPoint1: p(12.4, 3.6), controlPoint2: p(14.2, 5.4))
            bangs.close()
            bangs.fill()
            NSBezierPath(roundedRect: r(7.4, 9.9, 1.9, 0.95), xRadius: 0.45 * s, yRadius: 0.45 * s).fill()
            NSBezierPath(roundedRect: r(10.7, 9.9, 1.9, 0.95), xRadius: 0.45 * s, yRadius: 0.45 * s).fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Clippo"
        return image
    }
}
