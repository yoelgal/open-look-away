import SwiftUI

struct BeastBreakView: View {
    @ObservedObject var store: SessionStore
    var onDone: () -> Void
    var onSkip: () -> Void

    var body: some View {
        BreakStage(
            title: "On your feet.",
            subtitle: "\(store.engine.settings.beastPushUps) push-ups. Honor system.",
            countdown: clock,
            clock: now,
            snoozesLeft: max(0, store.engine.settings.snoozesPerDay - store.engine.snoozesUsedToday),
            skipTitle: canSkip ? "Skip Break" : nil,
            doneTitle: "Done",
            onSkip: canSkip ? onSkip : nil,
            onDone: onDone
        ) {
            ZStack {
                Image("BeastGlow")
                    .resizable()
                    .scaledToFill()
                LinearGradient(
                    colors: [.black.opacity(0.15), .black.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var clock: String {
        let s = max(0, Int(store.engine.remainingBreak.rounded(.up)))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private var now: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }

    private var canSkip: Bool {
        SkipLadder.canSkip(
            style: store.engine.settings.skipStyle,
            now: Date(),
            unlockedAt: store.engine.skipUnlockedAt,
            inBreak: true
        )
    }
}
