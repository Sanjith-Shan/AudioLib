#if os(macOS)
import SwiftUI
import CoreData

/// The ⌘, Preferences window — five tabs matching the Mac handoff.
struct MacPreferences: View {
    var body: some View {
        TabView {
            GeneralPane().tabItem { Label("General", systemImage: "gearshape") }
            PlaybackPane().tabItem { Label("Playback", systemImage: "play.fill") }
            CompanionPane().tabItem { Label("Companion", systemImage: "link") }
            StoragePane().tabItem { Label("Storage", systemImage: "internaldrive") }
            AboutPane().tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 660, height: 520)
    }
}

// MARK: - Form scaffolding

private struct FormRow<Content: View>: View {
    let label: String
    var description: String? = nil
    @ViewBuilder var content: Content
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label).font(.ui(12.5, weight: .semibold)).foregroundStyle(Theme.Colors.ink)
                .frame(width: 180, alignment: .trailing).padding(.top, 4)
            VStack(alignment: .leading, spacing: 6) {
                content
                if let description {
                    Text(description).font(.ui(11)).foregroundStyle(Theme.Colors.inkMute)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

private func paneScroll<C: View>(@ViewBuilder _ content: () -> C) -> some View {
    ScrollView { VStack(alignment: .leading, spacing: 20) { content() }.padding(.horizontal, 40).padding(.vertical, 24) }
        .background(Theme.Colors.paper)
}

// MARK: - General

private struct GeneralPane: View {
    @AppStorage("audiolib.hasOnboarded") private var hasOnboarded = true
    @AppStorage("mac.menuBarExtra") private var menuBarExtra = true
    var body: some View {
        paneScroll {
            FormRow(label: "Menu bar", description: "Show a playback control in the macOS menu bar.") {
                Toggle("Show AudioLib in the menu bar", isOn: $menuBarExtra)
            }
            FormRow(label: "Onboarding", description: "Show the welcome window again next launch.") {
                Button("Show Onboarding Again") { hasOnboarded = false }
            }
        }
    }
}

// MARK: - Playback

private struct PlaybackPane: View {
    @AppStorage("audiolib.defaultSkipInterval") private var skip: Double = 15
    @AppStorage("audiolib.defaultPlaybackSpeed") private var speed: Double = 1.0
    @AppStorage("audiolib.resumeOnLaunch") private var resumeOnLaunch = true
    @AppStorage("audiolib.pauseSleepWithPlayback") private var pauseSleep = false

    private let speeds: [Double] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

    var body: some View {
        paneScroll {
            FormRow(label: "Skip interval", description: "How far the skip buttons jump.") {
                HStack(spacing: 6) {
                    ForEach([10.0, 15, 30, 60], id: \.self) { v in
                        pill("\(Int(v))s", selected: skip == v) { skip = v }
                    }
                }
            }
            FormRow(label: "Default playback speed", description: "Applied when opening a book for the first time.") {
                Picker("", selection: $speed) {
                    ForEach(speeds, id: \.self) { Text(MacPlayback.rateLabel(Float($0))).tag($0) }
                }.pickerStyle(.segmented).labelsHidden().fixedSize()
            }
            FormRow(label: "On launch resume") {
                Toggle("Resume the last book automatically", isOn: $resumeOnLaunch)
            }
            FormRow(label: "Sleep timer when paused") {
                Toggle("Pause the sleep timer when playback pauses", isOn: $pauseSleep)
            }
            FormRow(label: "Hotkeys", description: "Available when AudioLib is the active app.") {
                let grid = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: grid, spacing: 8) {
                    hotkey("Play / Pause", ["Space"])
                    hotkey("Back 15s", ["⌘", "←"])
                    hotkey("Forward 15s", ["⌘", "→"])
                    hotkey("New Note", ["⌘", "N"])
                    hotkey("Bookmark", ["⌘", "B"])
                    hotkey("Sleep Timer", ["⌘", "⌥", "S"])
                }
            }
        }
    }

    private func pill(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.ui(12.5, weight: .semibold))
                .foregroundStyle(selected ? Theme.Colors.paperFg : Theme.Colors.ink)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(selected ? Theme.Colors.ink : Color.white.opacity(0.7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(selected ? Theme.Colors.ink : Theme.Colors.hair, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }.buttonStyle(.plain)
    }

    private func hotkey(_ label: String, _ keys: [String]) -> some View {
        HStack(spacing: 8) {
            Text(label).font(.ui(12)).foregroundStyle(Theme.Colors.ink)
            Spacer()
            ForEach(Array(keys.enumerated()), id: \.offset) { _, k in
                Text(k).font(.mono(11, weight: .semibold)).foregroundStyle(Theme.Colors.ink)
                    .frame(minWidth: 22, minHeight: 22).padding(.horizontal, 6)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.Colors.ink.opacity(0.12), lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.white.opacity(0.55))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.Colors.ink.opacity(0.06), lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

// MARK: - Companion

private struct CompanionPane: View {
    @AppStorage("audiolib.resolverMode") private var resolverMode = "onDevice"
    @AppStorage("audiolib.companionHost") private var host = ""
    @AppStorage("audiolib.companionPort") private var port = 8787
    @AppStorage("audiolib.allowCellular") private var allowCellular = false

    var body: some View {
        paneScroll {
            FormRow(label: "Audio source", description: "Run AudioLib Companion on your Mac to download faster and bypass throttling.") {
                Picker("", selection: $resolverMode) {
                    Text("On-Device").tag("onDevice")
                    Text("Companion").tag("companion")
                }.pickerStyle(.segmented).labelsHidden().fixedSize()
            }
            if resolverMode == "companion" {
                FormRow(label: "Host") {
                    TextField("mac-mini.local", text: $host).textFieldStyle(.roundedBorder).frame(width: 220)
                }
                FormRow(label: "Port") {
                    TextField("8787", value: $port, format: .number.grouping(.never))
                        .textFieldStyle(.roundedBorder).frame(width: 100)
                }
            }
            FormRow(label: "Connected devices", description: "Devices currently paired with this Mac over the local network.") {
                HStack(spacing: 6) {
                    Circle().fill(Theme.Colors.teal).frame(width: 8, height: 8)
                    Text(resolverMode == "companion" ? "\(host.isEmpty ? "localhost" : host):\(port)" : "Companion mode off")
                        .font(.ui(12.5, weight: .semibold)).foregroundStyle(Theme.Colors.tealInk)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Theme.Colors.tealSoft).clipShape(RoundedRectangle(cornerRadius: 7))
            }
            FormRow(label: "Cellular") {
                Toggle("Allow downloads on cellular", isOn: $allowCellular)
            }
        }
    }
}

// MARK: - Storage

private struct StoragePane: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var books: FetchedResults<Book>
    @State private var usage = "—"
    @State private var confirmWipe = false

    var body: some View {
        paneScroll {
            FormRow(label: "Library size") { Text(usage).font(.mono(13)).foregroundStyle(Theme.Colors.ink) }
            FormRow(label: "Books") { Text("\(books.count)").font(.mono(13)).foregroundStyle(Theme.Colors.ink) }
            FormRow(label: "Danger zone", description: "Removes every book and its audio file. Bookmarks and notes remain.") {
                Button(role: .destructive) { confirmWipe = true } label: {
                    Label("Delete All Books", systemImage: "trash")
                }
            }
        }
        .onAppear { usage = StorageUsageCalculator.calculate().formatted() }
        .confirmationDialog("Delete all books?", isPresented: $confirmWipe, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) { wipe() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func wipe() {
        PlayerController.shared.stop()
        AppRouter.shared.currentBookID = nil
        for book in books { FileStore.deleteBook(id: book.id); context.delete(book) }
        try? context.save()
        usage = StorageUsageCalculator.calculate().formatted()
    }
}

// MARK: - About

private struct AboutPane: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.Gradients.appIcon).frame(width: 84, height: 84)
                .overlay(Image(systemName: "headphones").font(.system(size: 38)).foregroundStyle(Theme.Colors.paperFg))
            Text("AudioLib").font(.serif(24, weight: .bold)).foregroundStyle(Theme.Colors.ink)
            Text("Version \(version)").font(.mono(12)).foregroundStyle(Theme.Colors.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.paper)
    }
}
#endif
