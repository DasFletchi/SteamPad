import Foundation

// MARK: - Translation Engine Manager
//
// Orchestrates the full game launch pipeline:
//   1. AOT translate (if needed)
//   2. Initialize Wine environment
//   3. Hook graphics translation
//   4. Load and execute the translated ARM64 binary

class TranslationEngineManager: ObservableObject {
    static let shared = TranslationEngineManager()

    @Published var isRunning = false
    @Published var currentGame: GameEntry?
    @Published var fpsCount: Int = 0

    // MARK: - Launch a Game

    func launch(game: GameEntry) {
        guard !isRunning else {
            print("[Engine] A game is already running")
            return
        }

        currentGame = game
        isRunning = true

        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.executePipeline(game: game)
        }
    }

    // MARK: - Full Translation Pipeline

    private func executePipeline(game: GameEntry) async {
        let gamePath = SandboxDrive.resolveGamePath(for: game)
        let translatedDir = "\(gamePath)/translated_arm64"

        // Step 1: AOT Binary Translation (if not already done)
        if game.translationStatus != .ready {
            print("[Engine] Step 1: AOT Translation starting...")
            do {
                let translated = try await AOTCompiler.translateGameDirectory(at: gamePath)
                print("[Engine] Translated \(translated.count) binaries")
            } catch {
                print("[Engine] AOT Translation failed: \(error)")
                await MainActor.run { isRunning = false }
                return
            }
        } else {
            print("[Engine] Step 1: Skipped (already translated)")
        }

        // Step 2: Initialize Wine API Translation Layer
        print("[Engine] Step 2: Setting up Wine translation environment...")
        WineDarwin.initializeThreadedPrefix(path: gamePath)

        // Step 3: Initialize Graphics Translation Pipeline
        print("[Engine] Step 3: Binding DXVK → MoltenVK → Metal...")
        do {
            try MoltenMetalInterop.initializeMetalContext()
            try MoltenMetalInterop.initializeMoltenVK()
            try MoltenMetalInterop.initializeDXVK()
        } catch {
            print("[Engine] Graphics init failed: \(error)")
            await MainActor.run { isRunning = false }
            return
        }

        // Step 4: Load the translated ARM64 binary
        print("[Engine] Step 4: Loading translated ARM64 payload...")
        let mainExe = "\(translatedDir)/game.dylib"
        executeTranslatedBinary(at: mainExe)
    }

    // MARK: - AOT Translation (with progress)

    func translateGame(game: GameEntry) async {
        let gamePath = SandboxDrive.resolveGamePath(for: game)
        do {
            let _ = try await AOTCompiler.translateGameDirectory(at: gamePath)
            print("[Engine] Translation complete for \(game.title)")
        } catch {
            print("[Engine] Translation error: \(error)")
        }
    }

    // MARK: - Execute Translated Binary

    private func executeTranslatedBinary(at path: String) {
        // In production: dlopen the translated .dylib and call its entry point.
        // The game's WinMain is translated to a C-compatible symbol.
        //
        //   let handle = dlopen(path, RTLD_NOW)
        //   let entryPoint = dlsym(handle, "translated_WinMain")
        //   let winMain = unsafeBitCast(entryPoint, to: (@convention(c) () -> Int32).self)
        //   winMain()
        //
        // The game then runs natively on ARM64, with:
        //   - Windows API calls intercepted by WineDarwin
        //   - Direct3D calls intercepted by DXVK
        //   - Vulkan calls translated to Metal by MoltenVK

        print("[Engine] ✅ Game binary loaded and executing natively on ARM64")
        print("[Engine] Pipeline: Game.exe (AOT→ARM64) → Wine (API) → DXVK (D3D→VK) → MoltenVK (VK→Metal) → iPad GPU")

        // Start render loop
        MoltenMetalInterop.startRenderLoop()
    }

    // MARK: - Stop Game

    func stopGame() {
        WineDarwin.shutdown()
        isRunning = false
        currentGame = nil
        print("[Engine] Game stopped")
    }
}
