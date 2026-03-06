import Foundation

// MARK: - Sandbox Drive Manager
//
// Per-game isolated WINEPREFIX containers within the iOS app sandbox.

enum SandboxDrive {

    static func resolveGamePath(for game: GameEntry) -> String {
        let docs = documentsDir()
        let safe = game.title
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ":", with: "")
        return "\(docs)/SteamLibrary/\(safe)"
    }

    static func resolvePrefixPath(for game: GameEntry) -> String {
        "\(resolveGamePath(for: game))/prefix"
    }

    static func createGameContainer(for game: GameEntry) throws {
        let fm = FileManager.default
        let prefix = resolvePrefixPath(for: game)
        let dirs = [
            "\(resolveGamePath(for: game))/game_files",
            "\(resolveGamePath(for: game))/translated_arm64",
            "\(resolveGamePath(for: game))/saves",
            "\(prefix)/drive_c/windows/system32",
            "\(prefix)/drive_c/users/steampad/Documents",
            "\(prefix)/drive_c/Program Files",
        ]
        for dir in dirs {
            try fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
    }

    static func deleteGameContainer(for game: GameEntry) throws {
        try FileManager.default.removeItem(atPath: resolveGamePath(for: game))
    }

    static func availableSpace() -> Int64 {
        let url = URL(fileURLWithPath: documentsDir())
        let vals = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return vals?.volumeAvailableCapacityForImportantUsage ?? 0
    }

    private static func documentsDir() -> String {
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "/tmp"
    }
}
