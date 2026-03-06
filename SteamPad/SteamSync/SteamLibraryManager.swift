import SwiftUI

// MARK: - Steam Library Manager
class SteamLibraryManager: ObservableObject {
    @Published var allGames: [GameEntry] = []
    @Published var recentGames: [GameEntry] = []
    @Published var featuredGames: [GameEntry] = []
    @Published var activeDownloads: [DownloadTask] = []
    @Published var activeTranslations: [TranslationTask] = []
    @Published var isAuthenticated = false

    var installedGames: [GameEntry] { allGames.filter { $0.isInstalled } }
    var translatedGames: [GameEntry] { allGames.filter { $0.translationStatus == .ready } }

    init() {
        // Demo data representing a synced Steam library
        let demoGames = [
            GameEntry(id: "1", appId: 570, title: "Dota 2", genre: "MOBA", accentColor: .red,
                      isInstalled: true, translationStatus: .ready, sizeBytes: 35_000_000_000,
                      winePrefixPath: "~/Documents/Prefixes/Dota2"),
            GameEntry(id: "2", appId: 730, title: "Counter-Strike 2", genre: "FPS", accentColor: .orange,
                      isInstalled: true, translationStatus: .ready, sizeBytes: 28_000_000_000,
                      winePrefixPath: "~/Documents/Prefixes/CS2"),
            GameEntry(id: "3", appId: 1245620, title: "Elden Ring", genre: "Action RPG", accentColor: Color(red: 0.8, green: 0.7, blue: 0.3),
                      isInstalled: true, translationStatus: .translating, sizeBytes: 50_000_000_000,
                      winePrefixPath: "~/Documents/Prefixes/EldenRing"),
            GameEntry(id: "4", appId: 1091500, title: "Cyberpunk 2077", genre: "RPG", accentColor: Color(red: 0.9, green: 0.9, blue: 0.1),
                      isInstalled: false, translationStatus: .notTranslated, sizeBytes: 70_000_000_000,
                      winePrefixPath: ""),
            GameEntry(id: "5", appId: 1145360, title: "Hades", genre: "Roguelike", accentColor: Color(red: 0.85, green: 0.2, blue: 0.15),
                      isInstalled: true, translationStatus: .ready, sizeBytes: 15_000_000_000,
                      winePrefixPath: "~/Documents/Prefixes/Hades"),
            GameEntry(id: "6", appId: 105600, title: "Terraria", genre: "Sandbox", accentColor: .green,
                      isInstalled: true, translationStatus: .ready, sizeBytes: 500_000_000,
                      winePrefixPath: "~/Documents/Prefixes/Terraria"),
            GameEntry(id: "7", appId: 400, title: "Portal", genre: "Puzzle", accentColor: .blue,
                      isInstalled: true, translationStatus: .ready, sizeBytes: 4_000_000_000,
                      winePrefixPath: "~/Documents/Prefixes/Portal"),
            GameEntry(id: "8", appId: 220, title: "Half-Life 2", genre: "FPS", accentColor: Color(red: 1.0, green: 0.5, blue: 0.0),
                      isInstalled: true, translationStatus: .ready, sizeBytes: 6_500_000_000,
                      winePrefixPath: "~/Documents/Prefixes/HL2"),
        ]

        allGames = demoGames
        recentGames = Array(demoGames.prefix(4))
        featuredGames = Array(demoGames.prefix(3))
    }

    // MARK: - Steam Web API Authentication
    func authenticate(username: String, password: String) async throws {
        // In production: hit Steam Web API for authentication token
        // POST https://api.steampowered.com/ISteamUserAuth/AuthenticateUser/v1/
        try await Task.sleep(for: .seconds(1))
        isAuthenticated = true
        await syncLibrary()
    }

    // MARK: - Sync Library via Steam Web API
    func syncLibrary() async {
        // In production: GET https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/
        // Parse JSON response and populate allGames with real AppIDs, titles, etc.
    }

    // MARK: - Download Game (SteamCMD / DepotDownloader equivalent)
    func downloadGame(_ game: GameEntry) async {
        let task = DownloadTask(id: game.id, gameTitle: game.title, downloadedMB: 0, totalMB: Int(game.sizeBytes / 1_000_000))
        await MainActor.run { activeDownloads.append(task) }

        // In production: use a SteamKit-compatible Swift library or
        // DepotDownloader to fetch game files via Steam CDN into the app sandbox
    }
}
