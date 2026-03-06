import SwiftUI

struct LibraryGridView: View {
    @EnvironmentObject var library: SteamLibraryManager
    @State private var searchText = ""
    @State private var selectedFilter: GameFilter = .all
    @State private var selectedGame: GameEntry?

    enum GameFilter: String, CaseIterable {
        case all = "All"
        case translated = "Translated"
        case installed = "Installed"
        case notInstalled = "Not Installed"
    }

    private var filteredGames: [GameEntry] {
        let base: [GameEntry]
        switch selectedFilter {
        case .all: base = library.allGames
        case .translated: base = library.translatedGames
        case .installed: base = library.installedGames
        case .notInstalled: base = library.allGames.filter { !$0.isInstalled }
        }
        if searchText.isEmpty { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: game list (SteamOS sidebar style)
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search library...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(GameFilter.allCases, id: \.self) { filter in
                            Button {
                                withAnimation { selectedFilter = filter }
                            } label: {
                                Text(filter.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(selectedFilter == filter ? .white : .gray)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedFilter == filter
                                            ? Color.blue.opacity(0.4)
                                            : Color.white.opacity(0.05)
                                    )
                                    .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // Game list
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredGames) { game in
                            GameListRow(game: game, isSelected: selectedGame?.id == game.id)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedGame = game
                                    }
                                }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .frame(width: 320)
            .background(Color.white.opacity(0.03))

            // Right: game detail pane
            if let game = selectedGame {
                GameDetailPane(game: game)
            } else {
                VStack {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.08))
                    Text("Select a game")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Game List Row
struct GameListRow: View {
    let game: GameEntry
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(game.accentColor.opacity(0.5))
                .frame(width: 40, height: 52)
                .overlay(
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(game.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(game.genre)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }

            Spacer()

            TranslationBadge(status: game.translationStatus)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.white.opacity(0.08) : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Game Detail Side Pane
struct GameDetailPane: View {
    let game: GameEntry
    @State private var isTranslating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero header
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [game.accentColor, Color.black],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                    .frame(height: 240)
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.title)
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                        Text(game.genre)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                }

                // Action buttons
                HStack(spacing: 12) {
                    if game.translationStatus == .ready {
                        Button {
                            TranslationEngineManager.shared.launch(game: game)
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("PLAY")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.35, green: 0.65, blue: 0.25))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    } else if game.isInstalled {
                        Button {
                            isTranslating = true
                            Task {
                                await TranslationEngineManager.shared.translateGame(game: game)
                                isTranslating = false
                            }
                        } label: {
                            HStack {
                                if isTranslating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text(isTranslating ? "TRANSLATING..." : "TRANSLATE")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(isTranslating)
                    } else {
                        Button {
                            // Download game
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                Text("INSTALL")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.4))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Details section
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "App ID", value: "\(game.appId)")
                    DetailRow(label: "Translation", value: game.translationStatus.label)
                    DetailRow(label: "Size", value: game.sizeDisplay)
                    DetailRow(label: "Prefix", value: game.winePrefixPath)
                }
                .padding(16)
                .background(Color.white.opacity(0.04))
                .cornerRadius(10)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.gray)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
    }
}
