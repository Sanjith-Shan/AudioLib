import SwiftUI
import CoreData
import MediaPlayer

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    // Resolver settings
    @AppStorage("audiolib.resolverMode") private var resolverMode: String = "onDevice"
    @AppStorage("audiolib.companionHost") private var companionHost: String = ""
    @AppStorage("audiolib.companionPort") private var companionPort: Int = 8787

    // Playback defaults
    @AppStorage("audiolib.defaultSkipInterval") private var skipInterval: Double = 15

    @State private var storageUsage: StorageUsageCalculator.Usage? = nil
    @State private var bookCount: Int = 0
    @State private var showingWipeConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Playback
                Section("Playback") {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Skip Interval")
                            .font(.bodyRegular)
                            .foregroundStyle(Theme.Colors.dark)

                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach([10.0, 15.0, 30.0, 60.0], id: \.self) { interval in
                                Button {
                                    skipInterval = interval
                                    updateSkipCommands(seconds: interval)
                                } label: {
                                    Text("\(Int(interval))s")
                                        .font(.bodySemibold)
                                        .foregroundStyle(skipInterval == interval ? Theme.Colors.white : Theme.Colors.dark)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(skipInterval == interval ? Theme.Colors.blue : Theme.Colors.surface)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }

                // Resolver
                Section("Audio Source") {
                    Picker("Resolver", selection: $resolverMode) {
                        Text("On-Device (YouTubeKit)").tag("onDevice")
                        Text("Companion Server").tag("companion")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, Theme.Spacing.xs)

                    if resolverMode == "companion" {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Server Host")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.midSlate)
                            TextField("192.168.1.X or hostname", text: $companionHost)
                                .font(.bodyRegular)

                            Text("Port")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.midSlate)
                                .padding(.top, Theme.Spacing.xs)
                            TextField("8787", value: $companionPort, format: .number)
                                .font(.bodyRegular)
                                .keyboardType(.numberPad)
                        }
                        .padding(.vertical, Theme.Spacing.xs)

                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Setup Instructions")
                                .font(.bodySemibold)
                                .foregroundStyle(Theme.Colors.dark)
                            Text("On your Mac: pip install flask yt-dlp && python companion_server.py")
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.midSlate)
                                .fontDesign(.monospaced)
                        }
                        .padding(.vertical, Theme.Spacing.xs)
                    }
                }

                // Storage
                Section("Storage") {
                    HStack {
                        Text("Library Size")
                            .font(.bodyRegular)
                            .foregroundStyle(Theme.Colors.dark)
                        Spacer()
                        if let usage = storageUsage {
                            Text("\(usage.formatted()) across \(bookCount) book\(bookCount == 1 ? "" : "s")")
                                .font(.bodyRegular)
                                .foregroundStyle(Theme.Colors.midSlate)
                        } else {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        showingWipeConfirmation = true
                    } label: {
                        Text("Delete All Books")
                            .font(.bodyRegular)
                            .foregroundStyle(Theme.Colors.danger)
                    }
                } header: {
                    Text("Danger Zone")
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                            .font(.bodyRegular)
                            .foregroundStyle(Theme.Colors.dark)
                        Spacer()
                        Text("1.0.0")
                            .font(.bodyRegular)
                            .foregroundStyle(Theme.Colors.midSlate)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadStats()
            }
            .confirmationDialog(
                "Delete All Books",
                isPresented: $showingWipeConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) { wipeLibrary() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all downloaded audiobooks and their audio files. This cannot be undone.")
            }
        }
    }

    private func loadStats() {
        Task.detached {
            let usage = StorageUsageCalculator.calculate()
            let req = NSFetchRequest<Book>(entityName: "Book")
            let count = (try? PersistenceController.shared.container.viewContext.count(for: req)) ?? 0
            await MainActor.run {
                self.storageUsage = usage
                self.bookCount = count
            }
        }
    }

    private func wipeLibrary() {
        Task { @MainActor in
            PlayerController.shared.stop()
            AppRouter.shared.currentBookID = nil
            AppRouter.shared.showingPlayer = false
        }

        context.perform {
            let req = NSFetchRequest<Book>(entityName: "Book")
            let books = (try? context.fetch(req)) ?? []
            for book in books {
                FileStore.deleteBook(id: book.id)
                context.delete(book)
            }
            try? context.save()
        }

        loadStats()
    }

    private func updateSkipCommands(seconds: Double) {
        let center = MPRemoteCommandCenter.shared()
        center.skipForwardCommand.preferredIntervals = [NSNumber(value: seconds)]
        center.skipBackwardCommand.preferredIntervals = [NSNumber(value: seconds)]
    }
}
