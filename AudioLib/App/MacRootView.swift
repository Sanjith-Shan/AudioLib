#if os(macOS)
import SwiftUI
import CoreData

enum MacSidebarItem: String, CaseIterable, Identifiable {
    case library = "Library"
    case download = "Download"
    case notes = "Notes"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .library:  return "books.vertical"
        case .download: return "arrow.down.circle"
        case .notes:    return "note.text"
        case .settings: return "gearshape"
        }
    }
}

struct MacRootView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var router = AppRouter.shared
    @State private var player = PlayerController.shared
    @State private var selectedItem: MacSidebarItem? = .library
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showInspector = true

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(MacSidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.systemImage)
                    .tag(item)
            }
            .navigationTitle("AudioLib")
            .listStyle(.sidebar)
            .frame(minWidth: 180)
        } detail: {
            detailContent
                .frame(minWidth: 520, minHeight: 480)
                .inspector(isPresented: $showInspector) {
                    MacNowPlayingPane()
                        .inspectorColumnWidth(min: 280, ideal: 320, max: 420)
                }
                .toolbar { playbackToolbar }
        }
        .frame(minWidth: 900, minHeight: 560)
        .environment(router)
        .onChange(of: router.selectedTab) { _, newValue in
            // Lets the Download empty-state CTA ("Go to Download") switch panes.
            if newValue == 0 { selectedItem = .download }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        switch selectedItem {
        case .library, .none:
            MacLibraryView()
                .environment(router)
                .environment(\.managedObjectContext, context)
        case .download:
            DownloadTabView()
                .environment(router)
                .environment(\.managedObjectContext, context)
        case .notes:
            NotesTabView()
                .environment(router)
                .environment(\.managedObjectContext, context)
        case .settings:
            SettingsView()
                .environment(router)
                .environment(\.managedObjectContext, context)
        }
    }

    // MARK: - Playback toolbar

    @ToolbarContentBuilder
    private var playbackToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if player.currentBook != nil {
                Button { player.skipBackward() } label: {
                    Image(systemName: "gobackward.15")
                }
                .help("Skip back")

                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                }
                .help(player.isPlaying ? "Pause" : "Play")

                Button { player.skipForward() } label: {
                    Image(systemName: "goforward.15")
                }
                .help("Skip forward")
            }

            Button { showInspector.toggle() } label: {
                Image(systemName: "sidebar.trailing")
            }
            .help("Toggle Now Playing")
        }
    }
}
#endif
