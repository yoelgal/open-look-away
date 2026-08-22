import AppKit
import SwiftUI

struct OpaqueGlass: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
    }
}

extension NSWindow {
    func installGlassHost<Content: View>(
        _ root: Content,
        material: NSVisualEffectView.Material = .underWindowBackground,
        cornerRadius: CGFloat = 0
    ) {
        let host = NSHostingView(rootView: root)
        host.wantsLayer = true
        host.layer?.isOpaque = false
        host.layer?.backgroundColor = NSColor.clear.cgColor
        let glass = NSVisualEffectView()
        glass.material = material
        glass.blendingMode = .behindWindow
        glass.state = .active
        glass.isEmphasized = true
        glass.autoresizingMask = [.width, .height]
        if cornerRadius > 0 {
            glass.wantsLayer = true
            glass.layer?.cornerRadius = cornerRadius
            glass.layer?.cornerCurve = .continuous
            glass.layer?.masksToBounds = true
        }
        host.autoresizingMask = [.width, .height]
        glass.addSubview(host)
        contentView = glass
        host.frame = glass.bounds
        isOpaque = false
        backgroundColor = .clear
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hasShadow = true
    }
}
