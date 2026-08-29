import SwiftUI

struct QuickLookView: View {
    @ObservedObject var store: SessionStore
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Text("OpenLookAway")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Button {
                        store.openSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                }
            }
            .padding(.top, 4)

            Picker("", selection: $tab) {
                Text("Now").tag(0)
                Text("Stats").tag(1)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)

            Group {
                if tab == 0 { now } else { stats }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            if let update = store.availableUpdate {
                UpdateNotice(update: update)
            }
        }
        .padding(22)
        .frame(width: 360, height: 400)
        .background(Color.clear)
    }

    private var now: some View {
        VStack(spacing: 16) {
            Text(clock)
                .font(.system(size: 64, weight: .regular, design: .rounded))
                .monospacedDigit()
            Text(caption)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Start break") { store.startBreakNow() }
                Button("+1m") { store.snooze(minutes: 1) }
                Button("+5m") { store.snooze(minutes: 5) }
            }
            .controlSize(.large)

            VStack(alignment: .leading, spacing: 6) {
                Text("Current focus \(focusMinutes) min.")
                Text("Upcoming: \(upcoming).")
            }
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)

            HStack {
                Text(store.engine.isBeast ? "Beast Mode is ON" : "Beast Mode is OFF")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Button {
                    store.engine.setBeast(!store.engine.settings.beastModeEnabled)
                } label: {
                    Capsule()
                        .fill(store.engine.isBeast
                              ? Color(red: 1, green: 0.45, blue: 0.18)
                              : Color.white.opacity(0.18))
                        .frame(width: 40, height: 24)
                        .overlay(alignment: store.engine.isBeast ? .trailing : .leading) {
                            Circle()
                                .fill(.white)
                                .frame(width: 20, height: 20)
                                .padding(2)
                        }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(.headline)
            Text("Focused \(Int(store.engine.statsFocusSecondsToday / 60)) min")
            Text("Breaks taken \(store.engine.statsBreaksToday)")
            Text("Snoozes used \(store.engine.snoozesUsedToday)/\(store.engine.settings.snoozesPerDay)")
            Text("Local only. No Screen Score.")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 24)
    }

    private var clock: String {
        let t = store.engine.phase == .breaking ? store.engine.remainingBreak : store.engine.remainingFocus
        let s = max(0, Int(t.rounded(.down)))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private var caption: String {
        switch store.engine.phase {
        case .breaking: return "On break"
        case .paused: return store.engine.lastPauseReason ?? "Paused"
        case .idle: return "Outside office hours"
        default: return "Break starts in"
        }
    }

    private var focusMinutes: Int {
        Int(store.engine.focusedSeconds / 60)
    }

    private var upcoming: String {
        store.engine.upcomingKind == .long
            ? "Long · \(store.engine.settings.longBreakMinutes)m"
            : "Short · \(store.engine.settings.shortBreakSeconds)s"
    }
}
