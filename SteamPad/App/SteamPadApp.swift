import SwiftUI

@main
struct SteamPadApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentRouter()
                .environmentObject(appState)
                .environmentObject(appState.library)
                .environmentObject(appState.engine)
                .environmentObject(appState.controller)
                .preferredColorScheme(.dark)
                .onAppear {
                    appState.controller.startListening()
                }
        }
    }
}

// MARK: - Central App State
class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .login
    @Published var isLoading = false

    let library = SteamLibraryManager()
    let engine = TranslationEngineManager()
    let controller = ControllerInputManager()

    func didLogin() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentScreen = .dashboard
        }
    }

    func launchGame(_ game: GameEntry) {
        engine.launch(game: game)
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = .inGame(game)
        }
    }

    func exitGame() {
        engine.stopGame()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = .dashboard
        }
    }
}

// MARK: - Content Router
struct ContentRouter: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Deep background
            Color(red: 0.04, green: 0.04, blue: 0.08)
                .ignoresSafeArea()

            switch appState.currentScreen {
            case .login:
                LoginView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .dashboard:
                RootView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))

            case .inGame(let game):
                InGameOverlayView(game: game)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.currentScreen)
    }
}