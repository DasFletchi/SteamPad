import SwiftUI
import Combine

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

    private var downloadTimers: [String: Timer] = [:]
    private var translationTimers: [String: Timer] = [:]

    init() {
        loadDemoLibrary()
    }

    // MARK: - Demo Data
    private func loadDemoLibrary() {
        let demoGames = [
            GameEntry(id: "1", appId: 570, title: "Dota 2", genre: "MOBA",
                      accentColor: Color(red: 0.8, green: 0.15, blue: 0.15),
                      isInstalled: true, translationStatus: .ready, sizeBytes: 35_000_000_000,
                      winePrefixPath: "~/Documents/Prefixes/Dota2"),
            GameEntry(id: "2", appId: 730, title: "Counter-Strike 2", genre: "FPS",
                      accentColor: Color(red: 0.9, green: 0.55, blue: 0.1),
                      isInstalled: true, translationStatus: .ready, sizeBytes: 28_000_000_000,
                      winePrefixPath: "~/Documents/Prefixes/CS2"),
            GameEntry(id: "3", appId: 1245620, title: "Elden Ring", genre: "Action RPG",
                      accentColor: Color(red: 0.75, green: 0.65, blue: 0.25),
                      isInstalled: true, translationStatus: .translating, sizeBytes: 50_000_000_000,
                      winePrefixPath: "~/Documents/Prefixes/EldenRing"),
            GameEntry(id: "4", appId: 1091500, title: "Cyberpunk 2077", genre: "RPG",
                      accentColor: Color(red: 0.95, green: 0.85, blue: 0.05),
                      isInstalled: false, translationStatus: .notTranslated, sizeBytes: 70_000_000_000,
                      winePrefixPath: ""),
            GameEntry(id: "5", appId: 1145360, title: "Hades", genre: "Roguelike",
                      accentColor: Color(red: 0.85, green: 0.2, blue: 0.12),
                      isInstalled: true, translationStatus: .ready, sizeBytes: 15_000_000_000,
                      winePrefixPath: "~/Documents/Prefixes/Hades"),
            GameEntry(id: "6", appId: 105600, title: "Terraria", genre: "Sandbox",
                      accentColor: Color(red: 0.2, green: 0.7, blue: 0.3),
                      isInstalled: true, translationStatus: .ready, sizeBytes: 500_000_000,
                      winePrefixPath: "~/Documents/Prefixes/Terraria"),
            GameEntry(id: "7", appId: 400, title: "Portal", genre: "Puzzle",
                      accentColor: Color(red: 0.2, green: 0.45, blue: 0.85),
                      isInstalled: true, translationStatus: .ready, sizeBytes: 4_000_000_000,
                      winePrefixPath: "~/Documents/Prefixes/Portal"),
            GameEntry(id: "8", appId: 220, title: "Half-Life 2", genre: "FPS",
                      accentColor: Color(red: 0.95, green: 0.5, blue: 0.05),
                      isInstalled: true, translationStatus: .ready, sizeBytes: 6_500_000_000,
                      winePrefixPath: "~/Documents/Prefixes/HL2"),
            GameEntry(id: "9", appId: 292030, title: "The Witcher 3", genre: "RPG",
                      accentColor: Color(red: 0.15, green: 0.35, blue: 0.15),
                      isInstalled: false, translationStatus: .notTranslated, sizeBytes: 50_000_000_000,
                      winePrefixPath: ""),
            GameEntry(id: "10", appId: 413150, title: "Stardew Valley", genre: "Simulation",
                      accentColor: Color(red: 0.4, green: 0.65, blue: 0.2),
                      isInstalled: true, translationStatus: .ready, sizeBytes: 500_000_000,
                      winePrefixPath: "~/Documents/Prefixes/StardewValley"),
        ]

        allGames = demoGames
        recentGames = Array(demoGames.prefix(5))
        featuredGames = [demoGames[0], demoGames[1], demoGames[4]]
    }

    // MARK: - Simulated Download (actually ticks the progress bar)

    func downloadGame(_ game: GameEntry) {
        let totalMB = Int(game.sizeBytes / 1_000_000)
        let task = DownloadTask(
            id: game.id,
            gameTitle: game.title,
            downloadedMB: 0,
            totalMB: totalMB,
            speedMBps: 0
        )
        activeDownloads.append(task)

        // Create a timer that simulates download progress
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            guard let idx = self.activeDownloads.firstIndex(where: { $0.id == game.id }) else {
                t.invalidate()
                return
            }

            let increment = Int.random(in: 200...800) // MB per tick
            self.activeDownloads[idx].downloadedMB = min(
                self.activeDownloads[idx].downloadedMB + increment,
                self.activeDownloads[idx].totalMB
            )
            self.activeDownloads[idx].speedMBps = Double.random(in: 40...120)

            if self.activeDownloads[idx].downloadedMB >= self.activeDownloads[idx].totalMB {
                t.invalidate()
                self.downloadTimers.removeValue(forKey: game.id)
                self.activeDownloads.removeAll { $0.id == game.id }

                // Mark game as installed
                if let gameIdx = self.allGames.firstIndex(where: { $0.id == game.id }) {
                    self.allGames[gameIdx].isInstalled = true
                }
            }
        }
        downloadTimers[game.id] = timer
    }

    // MARK: - Simulated Translation (actually ticks progress)

    func translateGame(_ game: GameEntry) {
        let totalFiles = Int.random(in: 40...200)
        let task = TranslationTask(
            id: game.id,
            gameTitle: game.title,
            progress: 0,
            currentFile: "game.exe",
            filesTranslated: 0,
            totalFiles: totalFiles
        )
        activeTranslations.append(task)

        // Update game status
        if let idx = allGames.firstIndex(where: { $0.id == game.id }) {
            allGames[idx].translationStatus = .translating
        }

        let fileNames = ["game.exe", "engine.dll", "d3d11.dll", "xinput1_3.dll",
                         "gamedata.dll", "renderer.dll", "audio.dll", "physics.dll",
                         "network.dll", "ui.dll", "scripts.dll", "content.dll"]

        let timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            guard let idx = self.activeTranslations.firstIndex(where: { $0.id == game.id }) else {
                t.invalidate()
                return
            }

            self.activeTranslations[idx].filesTranslated += 1
            self.activeTranslations[idx].progress = min(
                Double(self.activeTranslations[idx].filesTranslated) / Double(totalFiles),
                1.0
            )
            self.activeTranslations[idx].currentFile = fileNames.randomElement() ?? "module.dll"

            if self.activeTranslations[idx].progress >= 1.0 {
                t.invalidate()
                self.translationTimers.removeValue(forKey: game.id)
                self.activeTranslations.removeAll { $0.id == game.id }

                // Mark game as translated
                if let gameIdx = self.allGames.firstIndex(where: { $0.id == game.id }) {
                    self.allGames[gameIdx].translationStatus = .ready
                }
            }
        }
        translationTimers[game.id] = timer
    }
}
