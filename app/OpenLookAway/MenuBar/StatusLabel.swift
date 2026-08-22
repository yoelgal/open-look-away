import AppKit
import SwiftUI

enum StatusChip {
    static func image(text: String, beast: Bool) -> NSImage {
        let font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        let textSize = (text as NSString).size(withAttributes: [.font: font])
        let size = NSSize(width: ceil(8 + 16 + 6 + textSize.width + 10), height: 22)
        let ink = beast
            ? NSColor(calibratedRed: 0.72, green: 0.28, blue: 0.08, alpha: 1)
            : NSColor(calibratedRed: 0.15, green: 0.19, blue: 0.29, alpha: 1)
        let fill = beast
            ? NSColor(calibratedRed: 0.92, green: 0.40, blue: 0.14, alpha: 1)
            : ink
        return NSImage(size: size, flipped: false) { rect in
            let pill = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 11, yRadius: 11)
            fill.setFill()
            pill.fill()

            let face = NSRect(x: 7, y: 4, width: 14, height: 14)
            NSColor.white.setFill()
            NSBezierPath(ovalIn: face).fill()

            ink.setStroke()
            strokeEye(from: NSPoint(x: face.minX + 2.4, y: face.midY + 0.4), width: 3.6)
            strokeEye(from: NSPoint(x: face.midX + 1.2, y: face.midY + 0.4), width: 3.6)

            let textOrigin = NSPoint(
                x: 7 + 16 + 6,
                y: (rect.height - textSize.height) / 2 + 0.5
            )
            (text as NSString).draw(at: textOrigin, withAttributes: [
                .font: font,
                .foregroundColor: NSColor.white
            ])
            return true
        }
    }

    private static func strokeEye(from start: NSPoint, width: CGFloat) {
        let path = NSBezierPath()
        path.lineWidth = 1.5
        path.lineCapStyle = .round
        path.move(to: start)
        path.curve(
            to: NSPoint(x: start.x + width, y: start.y),
            controlPoint1: NSPoint(x: start.x + width * 0.3, y: start.y - 2.2),
            controlPoint2: NSPoint(x: start.x + width * 0.7, y: start.y - 2.2)
        )
        path.stroke()
    }
}

struct StatusLabel: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        Text(text)
            .monospacedDigit()
    }

    private var text: String {
        StatusChip.label(for: store.engine)
    }
}

extension StatusChip {
    @MainActor
    static func label(for engine: BreakEngine) -> String {
        switch engine.phase {
        case .idle:
            return "Off"
        case .paused:
            return "||"
        case .breaking:
            return compact(engine.remainingBreak)
        default:
            return compact(engine.remainingFocus)
        }
    }

    static func compact(_ t: TimeInterval) -> String {
        let s = max(0, Int(t.rounded(.down)))
        if s >= 60 { return "\(s / 60)m" }
        return "\(s)s"
    }
}
