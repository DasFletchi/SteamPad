import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var library: SteamLibraryManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("DOWNLOADS & TRANSLATIONS")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.gray.opacity(0.6))
                Spacer()
                if !library.activeDownloads.isEmpty || !library.activeTranslations.isEmpty {
                    Text("\(library.activeDownloads.count + library.activeTranslations.count) active")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            if library.activeDownloads.isEmpty && library.activeTranslations.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.08))
                            .frame(width: 80, height: 80)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green.opacity(0.4))
                    }
                    Text("All caught up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Text("No active downloads or translations.\nInstall a game from the Library tab to get started.")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        // Active translations first
                        if !library.activeTranslations.isEmpty {
                            sectionHeader("AOT TRANSLATION", icon: "arrow.triangle.2.circlepath", color: .blue)
                            ForEach(library.activeTranslations) { task in
                                TranslationTaskRow(task: task)
                            }
                        }

                        // Active downloads
                        if !library.activeDownloads.isEmpty {
                            sectionHeader("DOWNLOADING", icon: "arrow.down.circle.fill", color: .green)
                                .padding(.top, library.activeTranslations.isEmpty ? 0 : 12)
                            ForEach(library.activeDownloads) { task in
                                DownloadTaskRow(task: task)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
        }
        .foregroundColor(color.opacity(0.6))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

// MARK: - Translation Task Row
struct TranslationTaskRow: View {
    let task: TranslationTask

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(task.progress * 360))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: task.progress)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.gameTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    HStack(spacing: 6) {
                        Text("x86 → ARM64")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue.opacity(0.7))
                        Text("·")
                            .foregroundColor(.gray.opacity(0.3))
                        Text(task.currentFile)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(Int(task.progress * 100))%")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                    Text("\(task.filesTranslated)/\(task.totalFiles) files")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * task.progress)
                        .animation(.easeInOut(duration: 0.1), value: task.progress)
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Download Task Row
struct DownloadTaskRow: View {
    let task: DownloadTask

    private var progress: Double {
        guard task.totalMB > 0 else { return 0 }
        return Double(task.downloadedMB) / Double(task.totalMB)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.gameTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Downloading from Steam CDN...")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    Text(String(format: "%.1f MB/s", task.speedMBps))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.easeInOut(duration: 0.1), value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.1), lineWidth: 1)
        )
    }
}
