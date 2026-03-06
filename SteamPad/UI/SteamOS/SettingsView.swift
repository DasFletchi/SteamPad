import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var translationEngine: TranslationEngineManager
    @AppStorage("enableDXVK") private var enableDXVK = true
    @AppStorage("enableFSync") private var enableFSync = true
    @AppStorage("textureCompression") private var textureCompression = true
    @AppStorage("maxMemoryMB") private var maxMemoryMB = 3072
    @AppStorage("wineDebugLevel") private var wineDebugLevel = "warn"
    @AppStorage("steamUsername") private var steamUsername = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("SETTINGS")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.gray)

                // Steam Account
                settingsSection(title: "STEAM ACCOUNT") {
                    HStack {
                        Text("Username")
                            .foregroundColor(.gray)
                        Spacer()
                        TextField("Steam username", text: $steamUsername)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 200)
                    }
                }

                // Translation Engine
                settingsSection(title: "TRANSLATION ENGINE") {
                    settingsToggle("DXVK (Direct3D → Vulkan)", isOn: $enableDXVK)
                    Divider().opacity(0.2)
                    settingsToggle("FSync (Frame Synchronization)", isOn: $enableFSync)
                    Divider().opacity(0.2)
                    settingsToggle("ASTC Texture Compression", isOn: $textureCompression)
                }

                // Performance
                settingsSection(title: "PERFORMANCE") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Memory Limit")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(maxMemoryMB) MB")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                        Slider(value: Binding(
                            get: { Double(maxMemoryMB) },
                            set: { maxMemoryMB = Int($0) }
                        ), in: 1024...6144, step: 256)
                            .tint(.blue)
                    }

                    Divider().opacity(0.2)

                    HStack {
                        Text("Wine Debug Level")
                            .foregroundColor(.gray)
                        Spacer()
                        Picker("", selection: $wineDebugLevel) {
                            Text("Off").tag("off")
                            Text("Errors").tag("err")
                            Text("Warnings").tag("warn")
                            Text("Verbose").tag("trace")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 280)
                    }
                }

                // System Info
                settingsSection(title: "SYSTEM") {
                    DetailRow(label: "Runtime", value: "WineDarwin 9.0 (SingleProcess)")
                    Divider().opacity(0.2)
                    DetailRow(label: "Translator", value: "FEX-AOT Static ARM64")
                    Divider().opacity(0.2)
                    DetailRow(label: "Graphics", value: "DXVK 2.4 → MoltenVK 1.2")
                    Divider().opacity(0.2)
                    DetailRow(label: "Metal", value: "GPU Family Apple8+")
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.gray.opacity(0.6))

            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
        }
    }

    private func settingsToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
        .tint(.blue)
    }
}
