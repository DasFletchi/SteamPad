import SwiftUI
import MetalKit

// MARK: - Metal Rendering Surface for SwiftUI
//
// Wraps a CAMetalLayer in a UIViewRepresentable so SwiftUI can host the
// game's rendered output. MoltenVK draws translated Direct3D frames into
// this layer directly via Metal.

struct MetalGameView: UIViewRepresentable {
    func makeUIView(context: Context) -> MetalHostView {
        let view = MetalHostView()
        view.backgroundColor = .black

        // Configure the Metal layer
        if let metalLayer = view.layer as? CAMetalLayer {
            MoltenMetalInterop.bindMetalLayer(metalLayer)
        }

        return view
    }

    func updateUIView(_ uiView: MetalHostView, context: Context) {
        // Update drawable size on rotation
        if let metalLayer = uiView.layer as? CAMetalLayer {
            metalLayer.drawableSize = CGSize(
                width: uiView.bounds.width * uiView.contentScaleFactor,
                height: uiView.bounds.height * uiView.contentScaleFactor
            )
        }
    }
}

// MARK: - Metal Host UIView (CAMetalLayer-backed)
class MetalHostView: UIView {
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
}

// MARK: - In-Game Overlay
//
// Shows FPS counter, quick-settings, and virtual controls on top of the
// Metal rendering surface.

struct InGameOverlayView: View {
    @EnvironmentObject var engine: TranslationEngineManager
    @EnvironmentObject var controller: ControllerInputManager
    @State private var showQuickSettings = false

    var body: some View {
        ZStack {
            // Full-screen Metal rendering surface
            MetalGameView()
                .ignoresSafeArea()

            // HUD overlay
            VStack {
                // Top bar: FPS + game title
                HStack {
                    // FPS counter
                    HStack(spacing: 4) {
                        Circle()
                            .fill(fpsColor)
                            .frame(width: 6, height: 6)
                        Text("\(engine.fpsCount) FPS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)

                    Spacer()

                    // Quick settings toggle
                    Button {
                        withAnimation { showQuickSettings.toggle() }
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)

                    // Exit button
                    Button {
                        engine.stopGame()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                // Virtual controller (when no physical controller connected)
                if controller.isUsingTouchControls {
                    VirtualGamepadView()
                        .padding(.bottom, 20)
                }
            }

            // Quick settings panel
            if showQuickSettings {
                QuickSettingsPanel(isPresented: $showQuickSettings)
            }
        }
    }

    private var fpsColor: Color {
        if engine.fpsCount >= 50 { return .green }
        if engine.fpsCount >= 30 { return .yellow }
        return .red
    }
}

// MARK: - Virtual Gamepad Overlay

struct VirtualGamepadView: View {
    @EnvironmentObject var controller: ControllerInputManager

    var body: some View {
        HStack {
            // Left stick area
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 50, height: 50)
            }
            .padding(.leading, 40)

            Spacer()

            // Face buttons (A, B, X, Y)
            VStack(spacing: 8) {
                virtualButton("Y", color: .yellow)
                HStack(spacing: 24) {
                    virtualButton("X", color: .blue)
                    virtualButton("B", color: .red)
                }
                virtualButton("A", color: .green)
            }
            .padding(.trailing, 40)
        }
    }

    private func virtualButton(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 16, weight: .black))
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(color.opacity(0.4))
            .clipShape(Circle())
            .overlay(Circle().stroke(color.opacity(0.6), lineWidth: 1.5))
    }
}

// MARK: - Quick Settings Panel

struct QuickSettingsPanel: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("QUICK SETTINGS")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.gray)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }

            Toggle("DXVK Shader Cache", isOn: .constant(true))
                .tint(.blue)
            Toggle("FSync", isOn: .constant(true))
                .tint(.blue)
            Toggle("Show FPS", isOn: .constant(true))
                .tint(.blue)
        }
        .padding(20)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        )
        .foregroundColor(.white)
        .font(.system(size: 14))
    }
}
