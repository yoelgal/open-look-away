import SwiftUI

struct StatusLabel: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
                .monospacedDigit()
        }
    }

    private var icon: String {
        switch store.engine.phase {
        case .breaking: return "eye"
        case .paused, .idle: return "pause.circle"
        case .headsUp, .cursorCountdown: return "eye.slash"
        case .focusing: return "circle"
        }
    }

    private var text: String {
        switch store.engine.phase {
        case .breaking:
            return format(store.engine.remainingBreak)
        case .idle:
            return "Off"
        case .paused:
            return "Paused"
        default:
            return format(store.engine.remainingFocus)
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let s = Int(t.rounded(.down))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
