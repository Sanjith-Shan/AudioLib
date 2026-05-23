import SwiftUI
import CoreData

struct DownloadTabView: View {
    @ObservedObject private var downloadManager = DownloadManager.shared
    @Environment(\.managedObjectContext) private var context
    @State private var urlText = ""
    @State private var isDownloading = false
    @State private var errorMessage: String? = nil
    @State private var showingSettings = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DownloadJob.createdAt, ascending: false)],
        predicate: NSPredicate(format: "state != %@ AND state != %@", "done", "cancelled"),
        animation: .default
    ) private var activeJobs: FetchedResults<DownloadJob>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    PasteURLCard(
                        urlText: $urlText,
                        isDownloading: $isDownloading,
                        onDownload: startDownload
                    )
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.sm)

                    if let error = errorMessage {
                        Text(error)
                            .font(.bodyRegular)
                            .foregroundStyle(Theme.Colors.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.top, Theme.Spacing.md)
                    }

                    if !activeJobs.isEmpty {
                        SectionHeaderView(title: "Active")

                        VStack(spacing: 10) {
                            ForEach(activeJobs) { job in
                                DownloadRow(job: job)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .move(edge: .top)),
                                        removal: .opacity.combined(with: .scale(scale: 0.9))
                                    ))
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .animation(.easeInOut(duration: 0.25), value: activeJobs.count)
                    } else if !isDownloading {
                        EmptyStateView(
                            iconName: "arrow.down.circle",
                            title: "No Active Downloads",
                            subtitle: "Paste a YouTube link above to get started.",
                            circleSize: 72
                        )
                        .padding(.top, Theme.Spacing.xl)
                    }
                }
                .padding(.bottom, 140)
            }
            .background(Theme.Colors.paper.ignoresSafeArea())
            .navigationTitle("Download")
            .iOSNavigationBarLargeTitles()
            .toolbar {
                ToolbarItem(placement: .trailingBar) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.Colors.ink)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environment(\.managedObjectContext, context)
            }
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
