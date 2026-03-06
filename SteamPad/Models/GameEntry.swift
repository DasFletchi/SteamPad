import SwiftUI

// MARK: - Game Entry Model
struct GameEntry: Identifiable {
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
}

// MARK: - Translation Status
enum TranslationStatus: String {
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
}

// MARK: - Translation Task
struct TranslationTask: Identifiable {
    let id: String
    let gameTitle: String
    var progress: Double // 0.0 ... 1.0
}

// MARK: - Download Task
struct DownloadTask: Identifiable {
    let id: String
    let gameTitle: String
    var downloadedMB: Int
    var totalMB: Int
}
