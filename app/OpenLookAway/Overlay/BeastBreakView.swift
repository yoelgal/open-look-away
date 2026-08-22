import SwiftUI

struct BeastBreakView: View {
    @ObservedObject var store: SessionStore
    var onDone: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            Image("BeastFire")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            LinearGradient(
                colors: [.black.opacity(0.15), .black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                Spacer()
                Text("\(store.engine.settings.beastPushUps)")
                    .font(.system(size: 180, weight: .bold))
                    .foregroundStyle(.white)
                Text("push-ups")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundStyle(.white)
                    .padding(.bottom, 36)
                Button("Done", action: onDone)
                    .buttonStyle(.plain)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 220, height: 56)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
                Spacer()
            }

            VStack {
                Spacer()
                HStack {
                    Text("Open Look Away")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(24)
                    Spacer()
                    if canSkip {
                        Button("skip", action: onSkip)
                            .buttonStyle(.plain)
                            .foregroundStyle(.white.opacity(0.55))
                            .font(.system(size: 16))
                            .padding(28)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
