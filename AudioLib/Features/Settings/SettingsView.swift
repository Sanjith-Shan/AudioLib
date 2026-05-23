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

    // Companion server "Test Connection" state
    @State private var isTestingConnection = false
    @State private var connectionTestResult: ConnectionTestResult = .none

    enum ConnectionTestResult: Equatable {
        case none
        case success
        case failure(String)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    playbackSection
                    audioSourceSection
                    storageSection
                    dangerSection
                    aboutSection
                }
                .padding(.bottom, 36)
            }
            .background(Theme.Colors.paper.ignoresSafeArea())
            .navigationTitle("Settings")
            .iOSNavigationBarLargeTitles()
            .toolbar {
                ToolbarItem(placement: .trailingBar) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Colors.ink)
                }
            }
            .onAppear { loadStats() }
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

    // MARK: - Sections

    private var playbackSection: some View {
        VStack(spacing: 0) {
            SectionHeaderView(title: "Playback")
            VStack(alignment: .leading, spacing: 10) {
                Text("Skip interval")
                    .font(.ui(14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                HStack(spacing: 8) {
                    ForEach([10.0, 15.0, 30.0, 60.0], id: \.self) { interval in
                        Button {
                            skipInterval = interval
                            updateSkipCommands(seconds: interval)
                        } label: {
                            Text("\(Int(interval))s")
                                .font(.ui(14, weight: .semibold))
                                .foregroundStyle(skipInterval == interval ? Theme.Colors.paperFg : Theme.Colors.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(skipInterval == interval ? Theme.Colors.ink : Theme.Colors.cardSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(Theme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    private var audioSourceSection: some View {
        VStack(spacing: 0) {
            SectionHeaderView(title: "Audio Source")
            VStack(alignment: .leading, spacing: 0) {
                // Segmented toggle
                HStack(spacing: 0) {
                    segment("On-Device", value: "onDevice")
                    segment("Companion", value: "companion")
                }
                .padding(3)
                .background(Theme.Colors.cardSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                if resolverMode == "companion" {
                    VStack(spacing: 10) {
                        formField(label: "Host", text: $companionHost, placeholder: "192.168.1.X or hostname")
                            .onChange(of: companionHost) { _, newValue in
                                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                resolverMode = trimmed.isEmpty ? "onDevice" : "companion"
                                connectionTestResult = .none
                            }
                        portField
                    }
                    .padding(.top, 14)

                    testConnectionRow
                        .padding(.top, 12)

                    Text("Run AudioLib Companion on your Mac to download faster and bypass YouTube throttling.")
                        .font(.ui(12))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .lineSpacing(2)
                        .padding(.top, 12)
                }
            }
            .padding(16)
            .background(Theme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    private var storageSection: some View {
        VStack(spacing: 0) {
            SectionHeaderView(title: "Storage")
            VStack(spacing: 0) {
                settingsRow("Library size", value: storageUsage?.formatted() ?? "Calculating…")
                divider
                settingsRow("Books", value: "\(bookCount)")
            }
            .background(Theme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    private var dangerSection: some View {
        VStack(spacing: 0) {
            SectionHeaderView(title: "Danger Zone")
            Button(role: .destructive) {
                showingWipeConfirmation = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                    Text("Delete All Books")
                        .font(.ui(15, weight: .semibold))
                    Spacer()
                }
                .foregroundStyle(Theme.Colors.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 0) {
            SectionHeaderView(title: "About")
            VStack(spacing: 0) {
                settingsRow("Version", value: appVersion)
            }
            .background(Theme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Building blocks

    private var divider: some View {
        Rectangle().fill(Theme.Colors.hair).frame(height: 0.5).padding(.leading, 16)
    }

    private func segment(_ label: String, value: String) -> some View {
        Button {
            resolverMode = value
            connectionTestResult = .none
        } label: {
            Text(label)
                .font(.ui(13, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(resolverMode == value ? Theme.Colors.card : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: resolverMode == value ? .black.opacity(0.08) : .clear, radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }

    private func formField(label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label)
                .font(.ui(13))
                .foregroundStyle(Theme.Colors.inkSoft)
            Spacer()
            TextField(placeholder, text: text)
                .font(.mono(14))
                .foregroundStyle(Theme.Colors.ink)
                .multilineTextAlignment(.trailing)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.Colors.cardSoft)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var portField: some View {
        HStack {
            Text("Port")
                .font(.ui(13))
                .foregroundStyle(Theme.Colors.inkSoft)
            Spacer()
            TextField("8787", value: $companionPort, format: .number)
                .font(.mono(14))
                .foregroundStyle(Theme.Colors.ink)
                .multilineTextAlignment(.trailing)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .onChange(of: companionPort) { _, _ in connectionTestResult = .none }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.Colors.cardSoft)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var testConnectionRow: some View {
        HStack(spacing: 10) {
            Button { testConnection() } label: {
                HStack(spacing: 6) {
                    if isTestingConnection {
                        ProgressView().controlSize(.small).tint(Theme.Colors.tealInk)
                    } else {
                        switch connectionTestResult {
                        case .success:
                            Circle().fill(Theme.Colors.teal).frame(width: 8, height: 8)
                        default:
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 12))
                        }
                    }
                    Text(testLabel)
                        .font(.ui(13.5, weight: .semibold))
                }
                .foregroundStyle(connectionTestResult == .success ? Theme.Colors.tealInk : Theme.Colors.tealInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.Colors.tealSoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isTestingConnection || companionHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if case .failure(let reason) = connectionTestResult {
                Text(reason)
                    .font(.ui(12))
                    .foregroundStyle(Theme.Colors.red)
                    .lineLimit(2)
            }
        }
    }

    private var testLabel: String {
        if isTestingConnection { return "Testing…" }
        switch connectionTestResult {
        case .success: return "Connected to \(companionHost)"
        case .failure: return "Test Connection"
        case .none:    return "Test Connection"
        }
    }

    private func settingsRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.ui(15))
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            Text(value)
                .font(.mono(14))
                .foregroundStyle(Theme.Colors.inkSoft)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Logic

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

    private func testConnection() {
        let host = companionHost.trimmingCharacters(in: .whitespacesAndNewlines)
        let port = companionPort == 0 ? 8787 : companionPort
        guard !host.isEmpty,
              let url = URL(string: "http://\(host):\(port)/health") else {
            connectionTestResult = .failure("Invalid host")
            return
        }

        isTestingConnection = true
        connectionTestResult = .none

        Task {
            var req = URLRequest(url: url, timeoutInterval: 5)
            req.httpMethod = "GET"
            do {
                let (_, response) = try await URLSession.shared.data(for: req)
                await MainActor.run {
                    isTestingConnection = false
                    if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                        connectionTestResult = .success
                    } else {
                        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                        connectionTestResult = .failure("HTTP \(code)")
                    }
                }
            } catch {
                await MainActor.run {
                    isTestingConnection = false
                    connectionTestResult = .failure("Cannot reach server")
                }
            }
        }
    }
}
