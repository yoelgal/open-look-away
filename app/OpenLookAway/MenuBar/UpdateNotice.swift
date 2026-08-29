import AppKit
import SwiftUI

struct UpdateNotice: View {
    let update: AvailableUpdate
    @State private var showing = false
    @State private var copied = false
    @State private var problem: String?

    var body: some View {
        Button { showing = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle")
                Text("Update available")
                    .font(.system(size: 13, weight: .medium))
                Text(update.version)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showing, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Update to \(update.version)")
                    .font(.headline)
                if SelfUpdate.isPossible {
                    Text(SelfUpdate.whatUpdateDoes(sourceRoot: AppInfo.sourceRoot))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button("Update now") {
                            showing = false
                            problem = SelfUpdate.run(to: update.version)
                        }
                        .buttonStyle(.borderedProminent)
                        Button("What changed") { NSWorkspace.shared.open(update.url) }
                            .buttonStyle(.link)
                    }
                } else {
                    Text(SelfUpdate.howToUpdate(sourceRoot: AppInfo.sourceRoot))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(alignment: .top, spacing: 8) {
                        Text(SelfUpdate.command)
                            .font(.system(.callout, design: .monospaced))
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Button(copied ? "Copied" : "Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(SelfUpdate.command, forType: .string)
                            copied = true
                        }
                        .controlSize(.small)
                    }
                    .padding(10)
                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Button("What changed") { NSWorkspace.shared.open(update.url) }
                        .buttonStyle(.link)
                }
                if let problem {
                    Text(problem)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(16)
            .frame(width: 380)
        }
    }
}
