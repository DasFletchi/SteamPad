import Foundation

// MARK: - Translation Engine Manager
//
// Orchestrates the game execution pipeline with simulated steps
// that show realistic progress in the UI.

class TranslationEngineManager: ObservableObject {
    @Published var isRunning = false
    @Published var currentGame: GameEntry?
    @Published var fpsCount: Int = 0
    @Published var pipelineStep: String = ""
    @Published var pipelineProgress: Double = 0

    private var fpsTimer: Timer?

    // MARK: - Launch

    func launch(game: GameEntry) {
        guard !isRunning else { return }

        currentGame = game
        isRunning = true
        pipelineStep = "Initializing..."
        pipelineProgress = 0

        // Simulate the pipeline startup
        Task { @MainActor in
            await runPipeline(game: game)
        }
    }

    // MARK: - Simulated Pipeline

    @MainActor
    private func runPipeline(game: GameEntry) async {
        let steps: [(String, Double, TimeInterval)] = [
            ("Checking AOT translated binaries...", 0.1, 0.4),
            ("Loading WineDarwin translation layer...", 0.2, 0.5),
            ("Initializing single-process wineserver...", 0.3, 0.3),
            ("Setting up WINEPREFIX for \(game.title)...", 0.4, 0.4),
            ("Loading Metal GPU context...", 0.5, 0.3),
            ("Initializing MoltenVK (Vulkan → Metal)...", 0.6, 0.5),
            ("Loading DXVK (Direct3D → Vulkan)...", 0.7, 0.4),
            ("Mapping XInput controller bindings...", 0.8, 0.2),
            ("Loading translated ARM64 payload...", 0.9, 0.3),
            ("Executing \(game.title)...", 1.0, 0.2),
        ]

        for step in steps {
            guard isRunning else { return }
            pipelineStep = step.0
            withAnimation(.easeInOut(duration: 0.15)) {
                pipelineProgress = step.1
            }
            try? await Task.sleep(for: .seconds(step.2))
        }

        // Game is now "running" — start FPS counter
        startFPSSimulation()
    }

    // MARK: - FPS Simulation

    private func startFPSSimulation() {
        fpsTimer?.invalidate()
        fpsTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isRunning else { return }
            // Simulate realistic FPS fluctuation
            let base = 58
            let jitter = Int.random(in: -4...4)
            self.fpsCount = max(30, base + jitter)
        }
    }

    // MARK: - Stop

    func stopGame() {
        fpsTimer?.invalidate()
        fpsTimer = nil
        isRunning = false
        currentGame = nil
        fpsCount = 0
        pipelineStep = ""
        pipelineProgress = 0
    }
}
