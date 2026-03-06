import SwiftUI

// MARK: - Game Entry Model
struct GameEntry: Identifiable, Hashable {
    let id: String
    let appId: Int
    let title: String
    let genre: String
    let accentColor: Color
    var isInstalled: Bool
    var translationStatus: TranslationStatus
    var sizeBytes: Int64
    var winePrefixPath: String

    var sizeDisplay: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }

    // Hashable conformance (Color isn't Hashable by default)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GameEntry, rhs: GameEntry) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Translation Status
enum TranslationStatus: String, Hashable {
    case notTranslated = "Not Translated"
    case translating = "Translating"
    case ready = "Ready"
    case error = "Error"

    var label: String { rawValue }

    var color: Color {
        switch self {
        case .notTranslated: return .orange
        case .translating: return .blue
        case .ready: return .green
        case .error: return .red
        }
    }

    var icon: String {
        switch self {
        case .notTranslated: return "arrow.triangle.2.circlepath"
        case .translating: return "gearshape.2"
        case .ready: return "checkmark.seal.fill"
        case .error: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Translation Task
struct TranslationTask: Identifiable {
    let id: String
    let gameTitle: String
    var progress: Double // 0.0 ... 1.0
    var currentFile: String
    var filesTranslated: Int
    var totalFiles: Int
}

// MARK: - Download Task
struct DownloadTask: Identifiable {
    let id: String
    let gameTitle: String
    var downloadedMB: Int
    var totalMB: Int
    var speedMBps: Double
}

// MARK: - App Navigation State
enum AppScreen: Hashable {
    case login
    case dashboard
    case inGame(GameEntry)
}
