import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var library: SteamLibraryManager
    @State private var heroIndex = 0

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                heroSection
                sectionRow(title: "RECENT GAMES", games: library.recentGames)
                sectionRow(title: "READY TO PLAY", games: library.translatedGames)
                sectionRow(title: "ALL INSTALLED", games: library.installedGames)
                Spacer(minLength: 40)
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        TabView(selection: $heroIndex) {
            ForEach(Array(library.featuredGames.enumerated()), id: \.element.id) { index, game in
                ZStack(alignment: .bottomLeading) {
                    // Full-bleed gradient art
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: game.accentColor.opacity(0.8), location: 0),
                                    .init(color: game.accentColor.opacity(0.4), location: 0.5),
                                    .init(color: Color.black.opacity(0.95), location: 1.0)
                                ],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .overlay(
                            // Subtle game icon watermark
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 120))
                                .foregroundColor(.white.opacity(0.04))
                                .rotationEffect(.degrees(-15))
                                .offset(x: 80, y: -20)
                        )

                    // Info overlay
                    VStack(alignment: .leading, spacing: 10) {
                        // Genre pill
                        Text(game.genre.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)

                        Text(game.title)
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 8)

                        HStack(spacing: 14) {
                            TranslationBadge(status: game.translationStatus)

                            Text(game.sizeDisplay)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.gray)
                        }

                        HStack(spacing: 10) {
                            // Play button
                            if game.translationStatus == .ready {
                                Button {
                                    appState.launchGame(game)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 12))
                                        Text("PLAY")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 11)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.3, green: 0.7, blue: 0.2),
                                                Color(red: 0.25, green: 0.55, blue: 0.15)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .cornerRadius(6)
                                    .shadow(color: Color.green.opacity(0.3), radius: 8, y: 2)
                                }
                                .buttonStyle(.plain)
                            }

                            // Translate button
                            if game.isInstalled && game.translationStatus == .notTranslated {
                                Button {
                                    library.translateGame(game)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.system(size: 12))
                                        Text("TRANSLATE")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 11)
                                    .background(Color.blue.opacity(0.5))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(28)
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: 320)
        .padding(.horizontal, 24)
    }

    // MARK: - Horizontal game row
    private func sectionRow(title: String, games: [GameEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.gray.opacity(0.7))
                Spacer()
                Text("\(games.count) games")
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.4))
            }
            .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(games) { game in
                        GameCard(game: game)
                            .onTapGesture {
                                if game.translationStatus == .ready {
                                    appState.launchGame(game)
                                }
                            }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Game Card
struct GameCard: View {
    let game: GameEntry
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                // Cover art
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: game.accentColor.opacity(0.6), location: 0),
                                .init(color: game.accentColor.opacity(0.2), location: 0.6),
                                .init(color: Color.black, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 210)
                    .overlay(
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )

                // Badge
                TranslationBadge(status: game.translationStatus)
                    .padding(8)
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .shadow(color: game.accentColor.opacity(isPressed ? 0.4 : 0.15), radius: isPressed ? 16 : 6)
            .animation(.easeOut(duration: 0.15), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})

            Text(game.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(game.genre)
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(width: 160)
    }
}

// MARK: - Translation Status Badge
struct TranslationBadge: View {
    let status: TranslationStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 8))
            Text(status.label)
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(status.color.opacity(0.2), lineWidth: 0.5)
        )
        .cornerRadius(4)
    }
}
