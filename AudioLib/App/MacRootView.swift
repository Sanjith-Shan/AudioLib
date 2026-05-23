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
    @State private var selectedItem: MacSidebarItem? = .library
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List(MacSidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.systemImage)
                    .tag(item)
            }
            .navigationTitle("AudioLib")
            .listStyle(.sidebar)
        } detail: {
            // Detail pane
            Group {
                switch selectedItem {
                case .library, .none:
                    LibraryTabView()
                        .environment(router)
                        .environment(\.managedObjectContext, context)
                case .download:
                    DownloadTabView()
                        .environment(\.managedObjectContext, context)
                case .notes:
                    NotesTabView()
                        .environment(\.managedObjectContext, context)
                case .settings:
                    SettingsView()
                        .environment(\.managedObjectContext, context)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 520)
        // MiniPlayer footer
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if router.currentBookID != nil && !router.showingPlayer {
                MiniPlayer()
                    .environment(router)
                    .environment(\.managedObjectContext, context)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
            }
        }
        .sheet(isPresented: Bindable(router).showingPlayer) {
            if let bookID = router.currentBookID,
               let book = fetchBook(id: bookID) {
                PlayerView(book: book)
                    .environment(router)
                    .environment(\.managedObjectContext, context)
                    .frame(minWidth: 480, minHeight: 640)
            }
        }
        .environment(router)
    }

    private func fetchBook(id: UUID) -> Book? {
        let req = NSFetchRequest<Book>(entityName: "Book")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }
}
#endif
