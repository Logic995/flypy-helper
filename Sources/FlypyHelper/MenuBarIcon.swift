import AppKit

enum MenuBarIcon {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18))

        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.black.setStroke()
        NSColor.black.setFill()

        let key = NSBezierPath(
            roundedRect: NSRect(x: 2.0, y: 2.3, width: 14.0, height: 8.6),
            xRadius: 2.4,
            yRadius: 2.4
        )
        key.lineWidth = 1.65
        key.stroke()

        let keyGlow = NSBezierPath(
            roundedRect: NSRect(x: 5.5, y: 4.8, width: 7.0, height: 2.8),
            xRadius: 1.2,
            yRadius: 1.2
        )
        keyGlow.fill()

        let feather = NSBezierPath()
        feather.move(to: NSPoint(x: 3.7, y: 12.0))
        feather.curve(
            to: NSPoint(x: 16.1, y: 15.6),
            controlPoint1: NSPoint(x: 7.8, y: 16.5),
            controlPoint2: NSPoint(x: 13.1, y: 16.9)
        )
        feather.curve(
            to: NSPoint(x: 11.2, y: 8.8),
            controlPoint1: NSPoint(x: 14.8, y: 13.0),
            controlPoint2: NSPoint(x: 13.5, y: 10.1)
        )
        feather.curve(
            to: NSPoint(x: 3.7, y: 12.0),
            controlPoint1: NSPoint(x: 8.9, y: 9.9),
            controlPoint2: NSPoint(x: 6.2, y: 11.0)
        )
        feather.close()
        feather.fill()

        let spine = NSBezierPath()
        spine.move(to: NSPoint(x: 5.3, y: 12.0))
        spine.curve(
            to: NSPoint(x: 15.0, y: 14.5),
            controlPoint1: NSPoint(x: 8.5, y: 13.5),
            controlPoint2: NSPoint(x: 11.8, y: 14.3)
        )
        spine.lineWidth = 0.85
        spine.stroke()

        image.isTemplate = true
        return image
    }()
}
