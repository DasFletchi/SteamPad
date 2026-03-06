import SwiftUI

@main
struct SteamPadApp: App {
    @StateObject private var steamLibrary = SteamLibraryManager()
    @StateObject private var translationEngine = TranslationEngineManager()
    @StateObject private var controllerManager = ControllerInputManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(steamLibrary)
                .environmentObject(translationEngine)
                .environmentObject(controllerManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    controllerManager.startListening()
                }
        }
    }
}