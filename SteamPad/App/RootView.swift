import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: SteamTab = .home
    @State private var showUserMenu = false

    enum SteamTab: String, CaseIterable {
        case home = "Home"
        case library = "Library"
        case downloads = "Downloads"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .library: return "square.grid.2x2.fill"
            case .downloads: return "arrow.down.circle.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        ZStack {
            // Deep SteamOS background
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top nav bar
                SteamNavBar(selectedTab: $selectedTab, showUserMenu: $showUserMenu)

                // Content with transition
                ZStack {
                    switch selectedTab {
                    case .home:
                        HomeView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .leading)),
                                removal: .opacity
                            ))
                    case .library:
                        LibraryGridView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .leading)),
                                removal: .opacity
                            ))
                    case .downloads:
                        DownloadsView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .leading)),
                                removal: .opacity
                            ))
                    case .settings:
                        SettingsView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .leading)),
                                removal: .opacity
                            ))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }

            // User menu overlay
            if showUserMenu {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showUserMenu = false }

                VStack(alignment: .trailing) {
                    HStack {
                        Spacer()
                        UserMenuPanel(isPresented: $showUserMenu)
                            .padding(.top, 60)
                            .padding(.trailing, 24)
                    }
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showUserMenu)
    }
}

// MARK: - SteamOS-style top navigation bar
struct SteamNavBar: View {
    @Binding var selectedTab: RootView.SteamTab
    @Binding var showUserMenu: Bool
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var library: SteamLibraryManager

    var body: some View {
        HStack(spacing: 0) {
            // SteamPad Logo
            HStack(spacing: 8) {
                Image(systemName: "gamecontroller.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 0.6, green: 0.7, blue: 1.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("STEAMPAD")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2)
            }
            .padding(.leading, 24)

            Spacer()

            // Tab buttons
            HStack(spacing: 2) {
                ForEach(RootView.SteamTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11))
                            Text(tab.rawValue.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .tracking(0.5)
                        }
                        .foregroundColor(selectedTab == tab ? .white : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.1))
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Status indicators + user area
            HStack(spacing: 14) {
                // Download indicator
                if !library.activeDownloads.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                        Text("\(library.activeDownloads.count)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                }

                // Clock
                Text(Date(), style: .time)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)

                // User avatar
                Button {
                    showUserMenu.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(showUserMenu ? .white : .gray)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 24)
        }
        .frame(height: 52)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.6)
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                )
        )
    }
}

// MARK: - User Menu Panel
struct UserMenuPanel: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var library: SteamLibraryManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User info
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(library.isAuthenticated ? "Steam User" : "Demo Mode")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(library.isAuthenticated ? "Online" : "Offline")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
                Spacer()
            }
            .padding(16)

            Divider().background(Color.white.opacity(0.1))

            // Stats
            VStack(spacing: 8) {
                menuStatRow(icon: "gamecontroller", label: "Games", value: "\(library.allGames.count)")
                menuStatRow(icon: "checkmark.seal", label: "Translated", value: "\(library.translatedGames.count)")
                menuStatRow(icon: "internaldrive", label: "Installed", value: "\(library.installedGames.count)")
            }
            .padding(16)

            Divider().background(Color.white.opacity(0.1))

            // Sign out
            Button {
                isPresented = false
                appState.currentScreen = .login
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .font(.system(size: 13))
                .foregroundColor(.red)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 240)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                .shadow(color: .black.opacity(0.5), radius: 20)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func menuStatRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}
