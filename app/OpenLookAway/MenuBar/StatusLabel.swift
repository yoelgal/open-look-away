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

            // Beast face sits lower so horns stay inside the pill.
            let face = NSRect(x: 7, y: beast ? 2.5 : 4, width: 14, height: 14)
            NSColor.white.setFill()
            if beast {
                // Bases deep in the circle; tips short enough to clear the pill edge.
                fillHorn(
                    tip: NSPoint(x: face.minX + 0.6, y: face.maxY + 2.6),
                    baseL: NSPoint(x: face.minX + 2.2, y: face.maxY - 3.0),
                    baseR: NSPoint(x: face.minX + 5.6, y: face.maxY - 1.6)
                )
                fillHorn(
                    tip: NSPoint(x: face.maxX - 0.6, y: face.maxY + 2.6),
                    baseL: NSPoint(x: face.maxX - 5.6, y: face.maxY - 1.6),
                    baseR: NSPoint(x: face.maxX - 2.2, y: face.maxY - 3.0)
                )
            }
            NSBezierPath(ovalIn: face).fill()

            ink.setStroke()
            if beast {
                // Outer corners high, inner low — a sly squint, not calm closed eyes.
                strokeSlyEye(
                    outer: NSPoint(x: face.minX + 2.0, y: face.midY + 1.6),
                    inner: NSPoint(x: face.minX + 5.8, y: face.midY + 0.2)
                )
                strokeSlyEye(
                    outer: NSPoint(x: face.maxX - 2.0, y: face.midY + 1.6),
                    inner: NSPoint(x: face.maxX - 5.8, y: face.midY + 0.2)
                )
                strokeSmile(in: face)
            } else {
                strokeEye(from: NSPoint(x: face.minX + 2.4, y: face.midY + 0.4), width: 3.6)
                strokeEye(from: NSPoint(x: face.midX + 1.2, y: face.midY + 0.4), width: 3.6)
            }

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

    /// Angled brow-slash: outer high → inner low.
    private static func strokeSlyEye(outer: NSPoint, inner: NSPoint) {
        let path = NSBezierPath()
        path.lineWidth = 1.55
        path.lineCapStyle = .round
        path.move(to: outer)
        path.curve(
            to: inner,
            controlPoint1: NSPoint(x: outer.x + (inner.x - outer.x) * 0.35, y: outer.y - 0.3),
            controlPoint2: NSPoint(x: outer.x + (inner.x - outer.x) * 0.7, y: inner.y - 0.6)
        )
        path.stroke()
    }

    private static func fillHorn(tip: NSPoint, baseL: NSPoint, baseR: NSPoint) {
        let path = NSBezierPath()
        path.move(to: baseL)
        path.curve(
            to: tip,
            controlPoint1: NSPoint(x: baseL.x + (tip.x - baseL.x) * 0.15, y: baseL.y + 2.4),
            controlPoint2: NSPoint(x: tip.x - (tip.x - baseL.x) * 0.05, y: tip.y - 0.8)
        )
        path.curve(
            to: baseR,
            controlPoint1: NSPoint(x: tip.x + (baseR.x - tip.x) * 0.1, y: tip.y - 1.0),
            controlPoint2: NSPoint(x: baseR.x - (baseR.x - tip.x) * 0.2, y: baseR.y + 2.0)
        )
        path.close()
        path.fill()
    }

    private static func strokeSmile(in face: NSRect) {
        let path = NSBezierPath()
        path.lineWidth = 1.4
        path.lineCapStyle = .round
        let start = NSPoint(x: face.midX - 2.6, y: face.midY - 2.2)
        let end = NSPoint(x: face.midX + 2.6, y: face.midY - 2.2)
        path.move(to: start)
        path.curve(
            to: end,
            controlPoint1: NSPoint(x: face.midX - 1.2, y: face.midY - 4.2),
            controlPoint2: NSPoint(x: face.midX + 1.2, y: face.midY - 4.2)
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
