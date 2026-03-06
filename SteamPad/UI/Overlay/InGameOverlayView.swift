import SwiftUI

// MARK: - In-Game Overlay
struct InGameOverlayView: View {
    let game: GameEntry
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var engine: TranslationEngineManager
    @EnvironmentObject var controller: ControllerInputManager
    @State private var showQuickSettings = false
    @State private var showHUD = true
    @State private var hudOpacity: Double = 1.0

    var body: some View {
        ZStack {
            // Game rendering surface (simulated with gradient)
            gameRenderSurface

            if engine.pipelineProgress < 1.0 {
                // Pipeline loading screen
                pipelineLoadingView
            } else {
                // In-game HUD
                if showHUD {
                    inGameHUD
                }

                // Virtual controls (when no physical controller)
                if controller.isUsingTouchControls && engine.pipelineProgress >= 1.0 {
                    VirtualGamepadView()
                        .opacity(showHUD ? 1 : 0.3)
                }

                // Quick settings panel
                if showQuickSettings {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture { showQuickSettings = false }

                    QuickSettingsPanel(
                        isPresented: $showQuickSettings,
                        game: game
                    )
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showQuickSettings)
        .animation(.easeInOut(duration: 0.3), value: engine.pipelineProgress)
        .ignoresSafeArea()
        .statusBarHidden()
        .onTapGesture(count: 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showHUD.toggle()
            }
        }
    }

    // MARK: - Game Render Surface (simulated)
    private var gameRenderSurface: some View {
        ZStack {
            // Simulate a "game running" with animated gradient
            LinearGradient(
                stops: [
                    .init(color: game.accentColor.opacity(0.15), location: 0),
                    .init(color: Color.black, location: 0.5),
                    .init(color: game.accentColor.opacity(0.1), location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Grid overlay to simulate rendering
            Canvas { context, size in
                for x in stride(from: 0, to: size.width, by: 20) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(.white.opacity(0.01)), lineWidth: 0.5)
                }
                for y in stride(from: 0, to: size.height, by: 20) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(.white.opacity(0.01)), lineWidth: 0.5)
                }
            }

            // Center game icon
            if engine.pipelineProgress >= 1.0 {
                VStack(spacing: 8) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.06))
                    Text("\(game.title) is running")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.08))
                    Text("Double-tap to toggle HUD")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.05))
                }
            }
        }
    }

    // MARK: - Pipeline Loading View
    private var pipelineLoadingView: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Game title
                Text(game.title)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)

                // Pipeline step
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.blue)
                            .scaleEffect(0.8)
                        Text(engine.pipelineStep)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * engine.pipelineProgress)
                        }
                    }
                    .frame(height: 6)
                    .frame(maxWidth: 400)

                    Text("\(Int(engine.pipelineProgress * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }

                // Pipeline visualization
                VStack(alignment: .leading, spacing: 6) {
                    pipelineRow("game.exe", "AOT → ARM64", engine.pipelineProgress >= 0.3)
                    pipelineRow("Wine API", "Win32 → Darwin", engine.pipelineProgress >= 0.5)
                    pipelineRow("DXVK", "D3D → Vulkan", engine.pipelineProgress >= 0.7)
                    pipelineRow("MoltenVK", "Vulkan → Metal", engine.pipelineProgress >= 0.9)
                }
                .padding(.top, 8)
            }
        }
    }

    private func pipelineRow(_ name: String, _ action: String, _ done: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundColor(done ? .green : .gray.opacity(0.3))
            Text(name)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(done ? .white : .gray.opacity(0.4))
            Text("→")
                .foregroundColor(.gray.opacity(0.2))
            Text(action)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray.opacity(0.4))
        }
    }

    // MARK: - In-Game HUD
    private var inGameHUD: some View {
        VStack {
            HStack(alignment: .top) {
                // FPS counter
                HStack(spacing: 5) {
                    Circle()
                        .fill(fpsColor)
                        .frame(width: 6, height: 6)
                    Text("\(engine.fpsCount)")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(fpsColor)
                    Text("FPS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.7))
                .cornerRadius(6)

                // Game title pill
                Text(game.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(6)

                Spacer()

                // Quick settings
                Button {
                    withAnimation { showQuickSettings.toggle() }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // Exit
                Button {
                    appState.exitGame()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 50) // Safe area offset

            Spacer()
        }
    }

    private var fpsColor: Color {
        if engine.fpsCount >= 55 { return .green }
        if engine.fpsCount >= 40 { return .yellow }
        return .red
    }
}

// MARK: - Virtual Gamepad Overlay
struct VirtualGamepadView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                // Left stick
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 2)
                        .frame(width: 110, height: 110)
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 45, height: 45)
                }
                .padding(.leading, 50)

                Spacer()

                // Face buttons
                VStack(spacing: 6) {
                    faceButton("Y", .yellow)
                    HStack(spacing: 22) {
                        faceButton("X", .blue)
                        faceButton("B", .red)
                    }
                    faceButton("A", .green)
                }
                .padding(.trailing, 50)
            }
            .padding(.bottom, 30)
        }
    }

    private func faceButton(_ label: String, _ color: Color) -> some View {
        Text(label)
            .font(.system(size: 14, weight: .black))
            .foregroundColor(.white.opacity(0.8))
            .frame(width: 40, height: 40)
            .background(color.opacity(0.25))
            .clipShape(Circle())
            .overlay(Circle().stroke(color.opacity(0.35), lineWidth: 1.5))
    }
}

// MARK: - Quick Settings Panel
struct QuickSettingsPanel: View {
    @Binding var isPresented: Bool
    let game: GameEntry
    @EnvironmentObject var engine: TranslationEngineManager

    @State private var dxvkCache = true
    @State private var fsync = true
    @State private var showFPS = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("QUICK SETTINGS")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.gray)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider().background(Color.white.opacity(0.08))

            VStack(spacing: 14) {
                quickToggle("DXVK Shader Cache", isOn: $dxvkCache)
                quickToggle("FSync", isOn: $fsync)
                quickToggle("Show FPS Counter", isOn: $showFPS)

                Divider().background(Color.white.opacity(0.05))

                HStack {
                    Text("FPS")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(engine.fpsCount)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
            .padding(16)
        }
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.12))
                .shadow(color: .black.opacity(0.6), radius: 24)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func quickToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white)
        }
        .tint(.blue)
    }
}
