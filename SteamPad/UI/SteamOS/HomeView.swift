import SwiftUI

struct HomeView: View {
    @EnvironmentObject var library: SteamLibraryManager

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                // Hero carousel
                heroSection

                // Recent games row
                sectionRow(title: "RECENT GAMES", games: library.recentGames)

                // Translated & ready
                sectionRow(title: "READY TO PLAY", games: library.translatedGames)

                // All installed
                sectionRow(title: "INSTALLED", games: library.installedGames)
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: - Hero Section (featured game, SteamOS big picture style)
    private var heroSection: some View {
        TabView {
            ForEach(library.featuredGames) { game in
                ZStack(alignment: .bottomLeading) {
                    // Cover art placeholder gradient
                    LinearGradient(
                        colors: [game.accentColor, Color.black.opacity(0.9)],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                    .cornerRadius(16)

                    // Overlay info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.title)
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)

                        HStack(spacing: 12) {
                            TranslationBadge(status: game.translationStatus)
                            Text(game.genre)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Button {
                            TranslationEngineManager.shared.launch(game: game)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                Text("PLAY")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.35, green: 0.65, blue: 0.25))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(24)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: 320)
        .padding(.horizontal, 24)
    }

    // MARK: - Horizontal game row
    private func sectionRow(title: String, games: [GameEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .tracking(2)
                .foregroundColor(.gray)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(games) { game in
                        GameCard(game: game)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Game Card (SteamOS cover art tile)
struct GameCard: View {
    let game: GameEntry
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                // Cover art placeholder
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [game.accentColor.opacity(0.7), Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 210)
                    .overlay(
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.15))
                    )
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .shadow(color: game.accentColor.opacity(isHovered ? 0.5 : 0), radius: 12)
                    .animation(.easeOut(duration: 0.2), value: isHovered)

                // Status indicator
                TranslationBadge(status: game.translationStatus)
                    .padding(8)
            }
            .onHover { hovering in
                isHovered = hovering
            }

            Text(game.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(game.genre)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(width: 160)
    }
}

// MARK: - Translation Status Badge
struct TranslationBadge: View {
    let status: TranslationStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            Text(status.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.15))
        .cornerRadius(4)
    }
}
