import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SessionStore
    @State private var denylistText: String = ""

    var body: some View {
        TabView {
            breaks.tabItem { Label("Breaks", systemImage: "eye") }
            pause.tabItem { Label("Smart Pause", systemImage: "pause.circle") }
            beast.tabItem { Label("Beast Mode", systemImage: "flame") }
        }
        .frame(width: 520, height: 460)
        .onAppear { denylistText = store.engine.settings.denylistBundleIDs.joined(separator: "\n") }
    }

    private var settings: Binding<AppSettings> {
        Binding(
            get: { store.engine.settings },
            set: { store.engine.updateSettings($0) }
        )
    }

    private var breaks: some View {
        Form {
            Section("Focus") {
                Stepper("Show after \(store.engine.settings.focusMinutes) min", value: settings.focusMinutes, in: 1...120)
                Stepper("Short break \(store.engine.settings.shortBreakSeconds)s", value: settings.shortBreakSeconds, in: 5...120)
                Stepper("Long break \(store.engine.settings.longBreakMinutes) min every \(store.engine.settings.longBreakEvery)", value: settings.longBreakMinutes, in: 1...30)
                Stepper("Long every \(store.engine.settings.longBreakEvery) shorts", value: settings.longBreakEvery, in: 2...12)
            }
            Section("Skip") {
                Picker("Discipline", selection: settings.skipStyle) {
                    ForEach(SkipStyle.allCases) { style in
                        Text("\(style.title) — \(style.subtitle)").tag(style)
                    }
                }
                Stepper("Snoozes per day \(store.engine.settings.snoozesPerDay)", value: settings.snoozesPerDay, in: 0...20)
            }
            Section("Office hours") {
                Toggle("Limit to office hours", isOn: settings.officeHoursEnabled)
                Stepper("Start \(pad(store.engine.settings.officeStartHour)):\(pad(store.engine.settings.officeStartMinute))", value: settings.officeStartHour, in: 0...23)
                Stepper("Start minute \(pad(store.engine.settings.officeStartMinute))", value: settings.officeStartMinute, in: 0...59, step: 15)
                Stepper("End \(pad(store.engine.settings.officeEndHour)):\(pad(store.engine.settings.officeEndMinute))", value: settings.officeEndHour, in: 0...23)
                Stepper("End minute \(pad(store.engine.settings.officeEndMinute))", value: settings.officeEndMinute, in: 0...59, step: 15)
                Toggle("Weekdays only", isOn: settings.officeWeekdaysOnly)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var pause: some View {
        Form {
            Toggle("Typing or dragging", isOn: settings.pauseTyping)
            Toggle("Idle / away", isOn: settings.pauseIdle)
            Toggle("Mic or camera (meetings)", isOn: settings.pauseMeetings)
            Toggle("Video playback", isOn: settings.pauseVideo)
            Toggle("App denylist", isOn: settings.pauseDenylist)
            Stepper("Idle after \(Int(store.engine.settings.idleThresholdSeconds))s", value: settings.idleThresholdSeconds, in: 15...600, step: 15)
            Section("Denylist bundle IDs") {
                TextEditor(text: $denylistText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 80)
                    .onChange(of: denylistText) { text in
                        var next = store.engine.settings
                        next.denylistBundleIDs = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        store.engine.updateSettings(next)
                    }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var beast: some View {
        Form {
            Toggle("Beast Mode", isOn: settings.beastModeEnabled)
            Stepper("Push-ups \(store.engine.settings.beastPushUps)", value: settings.beastPushUps, in: 1...100)
            Text("Honor system. Tap Done when finished. No camera counting.")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding()
    }

    private func pad(_ n: Int) -> String { String(format: "%02d", n) }
}
