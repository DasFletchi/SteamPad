import SwiftUI

struct LibraryGridView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var library: SteamLibraryManager
    @State private var searchText = ""
    @State private var selectedFilter: GameFilter = .all
    @State private var selectedGame: GameEntry?

    enum GameFilter: String, CaseIterable {
        case all = "All"
        case translated = "Translated"
        case installed = "Installed"
        case notInstalled = "Not Installed"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .translated: return "checkmark.seal"
            case .installed: return "internaldrive"
            case .notInstalled: return "icloud.and.arrow.down"
            }
        }
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
            // Left sidebar
            VStack(spacing: 0) {
                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    TextField("Search library...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(GameFilter.allCases, id: \.self) { filter in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedFilter = filter
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: filter.icon)
                                        .font(.system(size: 10))
                                    Text(filter.rawValue)
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(selectedFilter == filter ? .white : .gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedFilter == filter
                                        ? Color.blue.opacity(0.35)
                                        : Color.white.opacity(0.04)
                                )
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            selectedFilter == filter
                                                ? Color.blue.opacity(0.4)
                                                : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                }

                // Game count
                HStack {
                    Text("\(filteredGames.count) games")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

                // Game list
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredGames) { game in
                            GameListRow(game: game, isSelected: selectedGame?.id == game.id)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.12)) {
                                        selectedGame = game
                                    }
                                }
                        }
                    }
                }
            }
            .frame(width: 320)
            .background(Color.white.opacity(0.02))

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 1)

            // Right: game detail
            if let game = selectedGame {
                GameDetailPane(game: game)
                    .id(game.id)
                    .transition(.opacity)
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.06))
                    Text("Select a game")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Choose from your library to view details")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.3))
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
                .fill(
                    LinearGradient(
                        colors: [game.accentColor.opacity(0.5), game.accentColor.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 38, height: 50)
                .overlay(
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.25))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(game.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(game.genre)
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.6))
            }

            Spacer()

            // Status dot
            Circle()
                .fill(game.translationStatus.color)
                .frame(width: 7, height: 7)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            isSelected
                ? Color.white.opacity(0.07)
                : Color.clear
        )
        .overlay(
            Rectangle()
                .fill(isSelected ? Color.blue : Color.clear)
                .frame(width: 3)
                .frame(maxHeight: .infinity),
            alignment: .leading
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Game Detail Pane
struct GameDetailPane: View {
    let game: GameEntry
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var library: SteamLibraryManager
    @State private var isTranslating = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Hero header
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: game.accentColor.opacity(0.7), location: 0),
                                    .init(color: game.accentColor.opacity(0.3), location: 0.5),
                                    .init(color: Color.black, location: 1.0)
                                ],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .frame(height: 220)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.genre.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.white.opacity(0.5))

                        Text(game.title)
                            .font(.system(size: 30, weight: .black))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                }

                // Action buttons
                actionButtons

                // Info grid
                infoGrid

                // Translation pipeline info
                pipelineInfo
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 10) {
            if game.translationStatus == .ready {
                // PLAY
                Button {
                    appState.launchGame(game)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("PLAY")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.7, blue: 0.2),
                                Color(red: 0.2, green: 0.55, blue: 0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(8)
                    .shadow(color: Color.green.opacity(0.2), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
            } else if game.isInstalled && game.translationStatus != .translating {
                // TRANSLATE
                Button {
                    library.translateGame(game)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("TRANSLATE TO ARM64")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.blue.opacity(0.5))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            } else if game.translationStatus == .translating {
                // Translating progress
                VStack(spacing: 6) {
                    HStack {
                        ProgressView()
                            .tint(.blue)
                            .scaleEffect(0.8)
                        Text("TRANSLATING x86 → ARM64...")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    ProgressView(value: translationProgress)
                        .tint(.blue)
                }
                .padding(.vertical, 8)
            } else {
                // INSTALL
                Button {
                    library.downloadGame(game)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("INSTALL (\(game.sizeDisplay))")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.blue.opacity(0.35))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var translationProgress: Double {
        library.activeTranslations.first(where: { $0.id == game.id })?.progress ?? 0
    }

    // MARK: - Info Grid
    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            infoCell(label: "APP ID", value: "\(game.appId)", icon: "number")
            infoCell(label: "STATUS", value: game.translationStatus.label, icon: "flag.fill")
            infoCell(label: "SIZE", value: game.sizeDisplay, icon: "internaldrive.fill")
            infoCell(label: "GENRE", value: game.genre, icon: "tag.fill")
        }
    }

    private func infoCell(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.gray.opacity(0.5))
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }

    // MARK: - Pipeline Info
    private var pipelineInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TRANSLATION PIPELINE")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.gray.opacity(0.5))

            VStack(spacing: 6) {
                pipelineStep("1", "AOT Binary Translation", "x86 PE → ARM64 Mach-O (.dylib)", game.translationStatus == .ready)
                pipelineStep("2", "Wine API Translation", "Win32 API → Darwin/POSIX", game.translationStatus == .ready)
                pipelineStep("3", "DXVK Graphics", "Direct3D → Vulkan", game.translationStatus == .ready)
                pipelineStep("4", "MoltenVK → Metal", "Vulkan → Apple Metal GPU", game.translationStatus == .ready)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.02))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }

    private func pipelineStep(_ num: String, _ title: String, _ subtitle: String, _ done: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(done ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
                    .frame(width: 24, height: 24)
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Text(num)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(done ? .white : .gray)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.5))
            }
            Spacer()
        }
    }
}
