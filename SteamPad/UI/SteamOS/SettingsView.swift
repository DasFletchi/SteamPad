import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("enableDXVK") private var enableDXVK = true
    @AppStorage("enableFSync") private var enableFSync = true
    @AppStorage("textureCompression") private var textureCompression = true
    @AppStorage("maxMemoryMB") private var maxMemoryMB = 3072
    @AppStorage("targetFPS") private var targetFPS = 60
    @AppStorage("wineDebugLevel") private var wineDebugLevel = "warn"
    @AppStorage("hapticFeedback") private var hapticFeedback = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("SETTINGS")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.gray.opacity(0.6))

                // Translation Engine
                settingsSection(title: "TRANSLATION ENGINE", icon: "cpu") {
                    settingsToggle("DXVK (Direct3D → Vulkan → Metal)", "Translates D3D9/11 draw calls", isOn: $enableDXVK)
                    Divider().background(Color.white.opacity(0.05))
                    settingsToggle("FSync (Frame Synchronization)", "Reduces stutter during rendering", isOn: $enableFSync)
                    Divider().background(Color.white.opacity(0.05))
                    settingsToggle("ASTC Texture Compression", "Converts textures to iPad GPU format on install", isOn: $textureCompression)
                }

                // Performance
                settingsSection(title: "PERFORMANCE", icon: "gauge.with.dots.needle.33percent") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Memory Limit")
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(maxMemoryMB) MB")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(maxMemoryMB) },
                                set: { maxMemoryMB = Int($0) }
                            ),
                            in: 1024...6144,
                            step: 256
                        )
                        .tint(.blue)
                        Text("iPad will terminate apps exceeding ~4GB. Keep this conservative.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.5))
                    }

                    Divider().background(Color.white.opacity(0.05))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Target FPS")
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(targetFPS) FPS")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(targetFPS >= 60 ? .green : .yellow)
                        }
                        Picker("", selection: $targetFPS) {
                            Text("30").tag(30)
                            Text("60").tag(60)
                            Text("120").tag(120)
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider().background(Color.white.opacity(0.05))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Wine Debug Level")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        Picker("", selection: $wineDebugLevel) {
                            Text("Off").tag("off")
                            Text("Errors").tag("err")
                            Text("Warnings").tag("warn")
                            Text("Verbose").tag("trace")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Input
                settingsSection(title: "INPUT", icon: "gamecontroller") {
                    settingsToggle("Haptic Feedback", "Vibration on supported controllers", isOn: $hapticFeedback)
                }

                // System Info
                settingsSection(title: "SYSTEM INFO", icon: "info.circle") {
                    systemInfoRow("Runtime", "WineDarwin 9.0 (SingleProcess)")
                    Divider().background(Color.white.opacity(0.05))
                    systemInfoRow("Translator", "FEX-AOT Static ARM64")
                    Divider().background(Color.white.opacity(0.05))
                    systemInfoRow("Graphics", "DXVK 2.4 → MoltenVK 1.2 → Metal 3")
                    Divider().background(Color.white.opacity(0.05))
                    systemInfoRow("GPU", "Apple GPU Family 9")
                    Divider().background(Color.white.opacity(0.05))
                    systemInfoRow("Version", "SteamPad v0.1.0 (build 1)")
                }

                // Danger zone
                settingsSection(title: "DATA", icon: "trash") {
                    Button {
                        // Clear shader cache
                    } label: {
                        HStack {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.orange)
                            Text("Clear Shader Cache")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().background(Color.white.opacity(0.05))

                    Button {
                        // Clear all translated binaries
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear All Translations")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 40)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
            }
            .foregroundColor(.gray.opacity(0.5))

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
            )
        }
    }

    private func settingsToggle(_ label: String, _ subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.5))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.blue)
        }
    }

    private func systemInfoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
