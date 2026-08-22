import SwiftUI

struct CalmBreakView: View {
    @ObservedObject var store: SessionStore
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.10, blue: 0.16).ignoresSafeArea()
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 6)
                        .frame(width: 280, height: 280)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 280, height: 280)
                    Text("\(seconds)")
                        .font(.system(size: 140, weight: .regular, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                Text("Look away.")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    if canSkip {
                        Button("skip", action: onSkip)
                            .buttonStyle(.plain)
                            .foregroundStyle(.white.opacity(0.5))
                            .font(.system(size: 16))
                            .padding(28)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var seconds: Int {
        max(0, Int(store.engine.remainingBreak.rounded(.up)))
    }

    private var progress: CGFloat {
        let total = store.engine.breakKind == .long
            ? store.engine.settings.longDuration
            : store.engine.settings.shortDuration
        guard total > 0 else { return 0 }
        return CGFloat(store.engine.remainingBreak / total)
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
