import SwiftUI
import CoreData

struct DownloadTabView: View {
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var urlText = ""
    @State private var isDownloading = false
    @State private var errorMessage: String? = nil

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DownloadJob.createdAt, ascending: false)],
        predicate: NSPredicate(format: "state != %@", "done"),
        animation: .default
    ) private var activeJobs: FetchedResults<DownloadJob>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    PasteURLCard(
                        urlText: $urlText,
                        isDownloading: $isDownloading,
                        onDownload: startDownload
                    )
                    .padding(.horizontal, Theme.Spacing.md)

                    if let error = errorMessage {
                        Text(error)
                            .font(.bodyRegular)
                            .foregroundStyle(Theme.Colors.danger)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, Theme.Spacing.md)
                    }

                    if !activeJobs.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Downloads")
                                .font(.titleMd)
                                .foregroundStyle(Theme.Colors.dark)
                                .padding(.horizontal, Theme.Spacing.md)

                            ForEach(activeJobs) { job in
                                DownloadRow(job: job)
                                    .padding(.horizontal, Theme.Spacing.md)
                            }
                        }
                    } else if !isDownloading {
                        EmptyStateView(
                            iconName: "arrow.down.circle.fill",
                            title: "No Active Downloads",
                            subtitle: "Paste a YouTube link above to get started"
                        )
                        .padding(.top, Theme.Spacing.xl)
                    }

                    Spacer()
                }
                .padding(.vertical, Theme.Spacing.lg)
            }
            .background(Theme.Colors.white)
            .navigationTitle("Download")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Actions

    private func startDownload() {
        let url = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return }

        isDownloading = true
        errorMessage = nil

        Task {
            do {
                try await DownloadManager.shared.startDownload(urlString: url)
                urlText = ""
            } catch {
                errorMessage = error.localizedDescription
            }
            isDownloading = false
        }
    }
}

#Preview {
    DownloadTabView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
