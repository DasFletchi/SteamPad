import SwiftUI

struct RootView: View {
    @State private var selectedTab: SteamTab = .home

    enum SteamTab: String, CaseIterable {
        case home = "Home"
        case library = "Library"
        case downloads = "Downloads"
        case settings = "Settings"
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
                // Top nav bar mimicking SteamOS
                SteamNavBar(selectedTab: $selectedTab)

                // Content
                Group {
                    switch selectedTab {
                    case .home:
                        HomeView()
                    case .library:
                        LibraryGridView()
                    case .downloads:
                        DownloadsView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - SteamOS-style top navigation bar
struct SteamNavBar: View {
    @Binding var selectedTab: RootView.SteamTab

    var body: some View {
        HStack(spacing: 0) {
            // SteamPad Logo
            HStack(spacing: 8) {
                Image(systemName: "gamecontroller.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                Text("STEAMPAD")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2)
            }
            .padding(.leading, 24)

            Spacer()

            // Tab buttons
            HStack(spacing: 4) {
                ForEach(RootView.SteamTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        Text(tab.rawValue.uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1)
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedTab == tab
                                    ? Color.white.opacity(0.1)
                                    : Color.clear
                            )
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // User / clock area
            HStack(spacing: 12) {
                Text(Date(), style: .time)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 24)
        }
        .frame(height: 56)
        .background(
            Color.black.opacity(0.6)
                .background(.ultraThinMaterial)
        )
    }
}
