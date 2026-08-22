import AppKit
import Foundation

enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    static var sourceRoot: String? {
        Bundle.main.object(forInfoDictionaryKey: "OLASourceRoot") as? String
    }

    static var updateCommand: String { updateCommand(sourceRoot: sourceRoot) }

    static func updateCommand(sourceRoot: String?) -> String {
        guard let root = sourceRoot else {
            return "curl -fsSL https://raw.githubusercontent.com/"
                + "\(UpdateCheck.repository)/main/install.sh | bash"
        }
        return "cd '\(root.replacingOccurrences(of: "'", with: #"'\''"#))' && git pull && ./install.sh"
    }
}

enum SelfUpdate {
    static var isPossible: Bool { updateScript(sourceRoot: AppInfo.sourceRoot, to: "") != nil }
    static var command: String { AppInfo.updateCommand }

    static func whatUpdateDoes(sourceRoot: String?) -> String {
        guard sourceRoot != nil else {
            return "A Terminal window runs the installer. OpenLookAway closes and reopens, a few seconds."
        }
        return "A Terminal window pulls and rebuilds. OpenLookAway closes and reopens, about two minutes."
    }

    static func howToUpdate(sourceRoot: String?) -> String {
        guard sourceRoot != nil else {
            return "This copy was downloaded ready to run. One line in Terminal fetches the new "
                + "version and replaces it, in a few seconds:"
        }
        return "OpenLookAway was built from a checkout that is no longer where this copy remembers it. "
            + "Run this wherever the repository is now:"
    }

    static func run(to version: String) -> String? {
        guard let source = updateScript(sourceRoot: AppInfo.sourceRoot, to: version) else {
            return "Cannot find the folder this copy was built from."
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("ola-update-\(UUID().uuidString).command")
        do {
            try source.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        } catch {
            return "Could not write the update script. \(error.localizedDescription)"
        }
        NSWorkspace.shared.open(url)
        return nil
    }

    static func updateScript(sourceRoot: String?, to version: String) -> String? {
        guard let root = sourceRoot else {
            return """
                #!/bin/bash
                # Written by OpenLookAway. Safe to delete.
                set -euo pipefail
                \(banner(to: version, doing: "Downloading and replacing this copy"))
                \(AppInfo.updateCommand(sourceRoot: nil))
                echo
                echo "  Done. This window can be closed."
                echo

                """
        }
        let fm = FileManager.default
        guard fm.fileExists(atPath: root + "/.git"),
              fm.isExecutableFile(atPath: root + "/install.sh") else { return nil }
        let quoted = root.replacingOccurrences(of: "'", with: #"'\''"#)
        return """
            #!/bin/bash
            # Written by OpenLookAway. Safe to delete.
            set -euo pipefail
            cd '\(quoted)'
            \(banner(to: version, doing: "Pulling and rebuilding in $(pwd)"))
            git pull --ff-only
            ./install.sh
            echo
            echo "  Done. This window can be closed."
            echo

            """
    }

    /// Quoted heredoc so the wordmark is never expanded by the shell. `doing` is echoed below
    /// so a `$(pwd)` in it still runs.
    private static func banner(to version: String, doing: String) -> String {
        """
        cat <<'OPENLOOKAWAY'

        \(wordmark)

        OPENLOOKAWAY
        echo "  \(AppInfo.version)  ─→  \(version)"
        echo "  \(doing)"
        echo
        """
    }

    /// Closed-eye mark + LOOK AWAY block letters for the Terminal update window.
    /// Eye hand-tuned; wordmark from Kimi (moonshotai/kimi-k2) then width-trimmed.
    static let wordmark = """
                                       .  ..  .
                                   .-+#@@@@@@#*-.
                                :+%@@@@@@@@@@@@%+:
                              =%@@@@@%****%@@@@@%=
                             -@@@@%*=:    :=*%@@@@-
                             *@@@*:   ....   :*@@@*
                             =@@%:  :*####*:  :%@@=
                              +@#   +@@@@@@+   #@+
                                =-   :%@@@@%:   -=
                                       .*@@*.
                                        .--.

    ██╗      ██████╗  ██████╗ ██╗  ██╗ █████╗ ██╗    ██╗ █████╗ ██╗   ██╗
    ██║     ██╔═══██╗██╔═══██╗██║ ██╔╝██╔══██╗██║    ██║██╔══██╗╚██╗ ██╔╝
    ██║     ██║   ██║██║   ██║█████╔╝ ███████║██║ █╗ ██║███████║ ╚████╔╝
    ██║     ██║   ██║██║   ██║██╔═██╗ ██╔══██║██║███╗██║██╔══██║  ╚██╔╝
    ███████╗╚██████╔╝╚██████╔╝██║  ██╗██║  ██║╚███╔███╔╝██║  ██║   ██║
    ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝
    """
}
