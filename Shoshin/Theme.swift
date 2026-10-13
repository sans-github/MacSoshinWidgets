import SwiftUI
import AppKit

/// Shared colors and sizes. Accent values come from MacRecordWidget so the two
/// apps read as siblings in the menu bar.
enum Theme {
    static let panelWidth: CGFloat = 440

    static let blue = Color(red: 0.0, green: 0.4784, blue: 1.0)        // #007AFF
    static let orange = Color(red: 1.0, green: 0.4784, blue: 0.2392)   // #FF7A3D
    static let red = Color(red: 1.0, green: 0.2196, blue: 0.2353)      // #FF383C
    static let breath = Color(red: 0.353, green: 0.784, blue: 0.722)   // #5AC8B8

    /// Focus progress amber. Lighter on dark backgrounds, deeper on light ones,
    /// so the filled segments keep the same contrast in both appearances.
    static let amber = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.910, green: 0.753, blue: 0.376, alpha: 1)  // #E8C060
            : NSColor(red: 0.851, green: 0.663, blue: 0.227, alpha: 1)  // #D9A93A
    })

    static let rowFill = Color(nsColor: .quaternaryLabelColor).opacity(0.5)
    static let separator = Color(nsColor: .separatorColor)

    /// Menu bar glyph: an enso, a single open brush circle. Drawn rather than an
    /// SF Symbol because no symbol has the gap. Template, so it follows the menu
    /// bar's light and dark tint.
    static let enso: NSImage = {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { _ in
            let path = NSBezierPath()
            path.appendArc(withCenter: NSPoint(x: 8, y: 8), radius: 6,
                           startAngle: 100, endAngle: 60, clockwise: false)
            path.lineWidth = 2
            path.lineCapStyle = .round
            NSColor.black.setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }()
}
