import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject var library: SteamLibraryManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("DOWNLOADS & TRANSLATIONS")
                .font(.system(size: 14, weight: .bold))
                .tracking(2)
                .foregroundColor(.gray)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

            if library.activeDownloads.isEmpty && library.activeTranslations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.green.opacity(0.4))
                    Text("All caught up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    Text("No active downloads or translations.")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // Active translations
                        ForEach(library.activeTranslations) { task in
                            TranslationTaskRow(task: task)
                        }

                        // Active downloads
                        ForEach(library.activeDownloads) { task in
                            DownloadTaskRow(task: task)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct TranslationTaskRow: View {
    let task: TranslationTask

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.gameTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("AOT Translation: x86 → ARM64")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(task.progress * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                ProgressView(value: task.progress)
                    .tint(.blue)
                    .frame(width: 120)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}

struct DownloadTaskRow: View {
    let task: DownloadTask

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.gameTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("Downloading from Steam depot...")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(task.downloadedMB) / \(task.totalMB) MB")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
                ProgressView(value: Double(task.downloadedMB) / Double(max(task.totalMB, 1)))
                    .tint(.green)
                    .frame(width: 120)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}
