import SwiftUI

struct CalmBreakView: View {
    @ObservedObject var store: SessionStore
    var onSkip: () -> Void

    var body: some View {
        BreakStage(
            title: "Look away.",
            subtitle: "Rest your eyes on something far until the countdown ends.",
            countdown: clock,
            clock: now,
            snoozesLeft: max(0, store.engine.settings.snoozesPerDay - store.engine.snoozesUsedToday),
            skipTitle: canSkip ? "Skip Break" : nil,
            doneTitle: nil,
            onSkip: canSkip ? onSkip : nil,
            onDone: nil
        ) {
            ZStack {
                Image("CalmHorizon")
                    .resizable()
                    .scaledToFill()
                LinearGradient(
                    colors: [.black.opacity(0.08), .black.opacity(0.35)],
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

struct BreakStage<Background: View>: View {
    var title: String
    var subtitle: String
    var countdown: String
    var clock: String
    var snoozesLeft: Int
    var skipTitle: String?
    var doneTitle: String?
    var onSkip: (() -> Void)?
    var onDone: (() -> Void)?
    @ViewBuilder var background: () -> Background

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                VStack(spacing: 0) {
                    Text(title)
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                    Text(subtitle)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .padding(.top, 14)
                        .padding(.horizontal, 72)
                    Rectangle()
                        .fill(.white.opacity(0.28))
                        .frame(width: 48, height: 1)
                        .padding(.top, 28)
                        .padding(.bottom, 22)
                    Text(countdown)
                        .font(.system(size: 64, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                        .monospacedDigit()
                }
                .frame(width: geo.size.width, height: geo.size.height)

                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                        Text(clock)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 36)
                    Spacer()
                    HStack(spacing: 14) {
                        if let skipTitle, let onSkip {
                            pill(skipTitle, systemImage: "forward.fill", action: onSkip)
                        }
                        if let doneTitle, let onDone {
                            pill(doneTitle, systemImage: "checkmark", action: onDone)
                        }
                    }
                    Text("\(snoozesLeft) snoozes available")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
    }

    private func pill(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(.white.opacity(0.16), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
