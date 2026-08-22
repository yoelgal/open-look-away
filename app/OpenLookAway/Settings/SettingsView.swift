import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SessionStore
    @State private var tab = 0
    @State private var denylistText: String = ""
    @State private var checking = false
    @State private var checkResult: UpdateCheck.Outcome?
    @State private var updateProblem: String?

    var body: some View {
        VStack(spacing: 16) {
            Picker("", selection: $tab) {
                Text("Breaks").tag(0)
                Text("Pause").tag(1)
                Text("Beast").tag(2)
                Text("Updates").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)

            Group {
                switch tab {
                case 1: pause
                case 2: beast
                case 3: about
                default: breaks
                }
            }
        }
        .padding(.top, 48)
        .padding(.bottom, 16)
        .frame(width: 520, height: 520)
        .background(Color.clear)
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
            Section("Timing") {
                Stepper("Focus  \(store.engine.settings.focusMinutes) min", value: settings.focusMinutes, in: 1...120)
                Stepper("Short break  \(store.engine.settings.shortBreakSeconds)s", value: settings.shortBreakSeconds, in: 5...120)
                Stepper("Long break  \(store.engine.settings.longBreakMinutes) min", value: settings.longBreakMinutes, in: 1...30)
                Stepper("Long every  \(store.engine.settings.longBreakEvery) shorts", value: settings.longBreakEvery, in: 2...12)
            }
            Section("Skip") {
                Picker("Discipline", selection: settings.skipStyle) {
                    ForEach(SkipStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                Text(store.engine.settings.skipStyle.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Stepper("Snoozes  \(store.engine.settings.snoozesPerDay) / day", value: settings.snoozesPerDay, in: 0...20)
            }
            Section("Office hours") {
                Toggle("Only during office hours", isOn: settings.officeHoursEnabled)
                if store.engine.settings.officeHoursEnabled {
                    Stepper(
                        "Start  \(pad(store.engine.settings.officeStartHour)):\(pad(store.engine.settings.officeStartMinute))",
                        value: settings.officeStartHour, in: 0...23
                    )
                    Stepper(
                        "End  \(pad(store.engine.settings.officeEndHour)):\(pad(store.engine.settings.officeEndMinute))",
                        value: settings.officeEndHour, in: 0...23
                    )
                    Toggle("Weekdays only", isOn: settings.officeWeekdaysOnly)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private var pause: some View {
        Form {
            Section("Hold the break when") {
                Toggle("Typing or dragging", isOn: settings.pauseTyping)
                Toggle("Idle", isOn: settings.pauseIdle)
                Toggle("Meeting (mic or camera)", isOn: settings.pauseMeetings)
                Toggle("Video playback", isOn: settings.pauseVideo)
                Toggle("Listed apps", isOn: settings.pauseDenylist)
                if store.engine.settings.pauseIdle {
                    Stepper(
                        "Idle after  \(Int(store.engine.settings.idleThresholdSeconds))s",
                        value: settings.idleThresholdSeconds, in: 15...600, step: 15
                    )
                }
            }
            if store.engine.settings.pauseDenylist {
                Section("App bundle IDs") {
                    TextEditor(text: $denylistText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 80)
                        .onChange(of: denylistText) { text in
                            var next = store.engine.settings
                            next.denylistBundleIDs = text.split(separator: "\n").map {
                                $0.trimmingCharacters(in: .whitespaces)
                            }.filter { !$0.isEmpty }
                            store.engine.updateSettings(next)
                        }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private var beast: some View {
        Form {
            Section {
                Toggle("Beast Mode", isOn: settings.beastModeEnabled)
                    .tint(Color(red: 1, green: 0.45, blue: 0.18))
                if store.engine.settings.beastModeEnabled {
                    Stepper("Push-ups  \(store.engine.settings.beastPushUps)", value: settings.beastPushUps, in: 1...100)
                }
                Text("Optional. Each break asks for push-ups on the honor system. Tap Done when finished.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private var about: some View {
        Form {
            Section {
                LabeledContent("This copy") {
                    Text("Version \(AppInfo.version)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Button(checking ? "Checking…" : "Check now") {
                        checking = true
                        checkResult = nil
                        Task {
                            checkResult = await store.checkForUpdates()
                            checking = false
                        }
                    }
                    .disabled(checking)
                    Spacer()
                }
                if let checkResult {
                    switch checkResult {
                    case .update(let update):
                        Text("Version \(update.version) is available.")
                            .font(.callout)
                            .foregroundStyle(Color(nsColor: .systemGreen))
                        HStack(spacing: 12) {
                            if SelfUpdate.isPossible {
                                Button("Update now") {
                                    updateProblem = SelfUpdate.run(to: update.version)
                                }
                                .buttonStyle(.borderedProminent)
                            } else {
                                Button("Copy install command") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(SelfUpdate.command, forType: .string)
                                }
                            }
                            Button("What changed") {
                                NSWorkspace.shared.open(update.url)
                            }
                            .buttonStyle(.link)
                        }
                        if let updateProblem {
                            Text(updateProblem)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        if SelfUpdate.isPossible {
                            Text(SelfUpdate.whatUpdateDoes(sourceRoot: AppInfo.sourceRoot))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    case .upToDate:
                        Text("You are up to date.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    case .failed(let why):
                        Text(why)
                            .font(.callout)
                            .foregroundStyle(Color(nsColor: .systemOrange))
                    case .skipped:
                        EmptyView()
                    }
                }
            }
            Section {
                Toggle("Check automatically", isOn: Binding(
                    get: { UpdateCheck.isEnabled(store.defaults) },
                    set: { UpdateCheck.setEnabled($0, defaults: store.defaults) }
                ))
                Text("OpenLookAway asks GitHub once a day whether a newer version exists. It sends nothing about you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private func pad(_ n: Int) -> String { String(format: "%02d", n) }
}
