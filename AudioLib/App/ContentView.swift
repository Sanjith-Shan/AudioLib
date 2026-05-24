#if os(iOS)
import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var router = AppRouter.shared
    @AppStorage("audiolib.hasOnboarded") private var hasOnboarded = false
    @State private var showOnboarding = false

    var body: some View {
        TabView(selection: Bindable(router).selectedTab) {
            DownloadTabView()
                .tabItem { Label("Download", systemImage: "arrow.down.circle") }
                .tag(0)
            LibraryTabView()
                .tabItem { Label("Library", systemImage: "books.vertical") }
                .tag(1)
            NotesTabView()
                .tabItem { Label("Notes", systemImage: "note.text") }
                .tag(2)
        }
        .tint(Theme.Colors.teal)
        .background(Theme.Colors.paper, ignoresSafeAreaEdges: .all)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MiniPlayer()
                .environment(router)
                .environment(\.managedObjectContext, context)
        }
        .sheet(isPresented: Bindable(router).showingPlayer) {
            if let bookID = router.currentBookID,
               let book = fetchBook(id: bookID) {
                PlayerView(book: book)
                    .environment(router)
                    .environment(\.managedObjectContext, context)
            }
        }
        .environment(router)
        .onAppear { showOnboarding = !hasOnboarded }
        .sheet(isPresented: $showOnboarding, onDismiss: { hasOnboarded = true }) {
            OnboardingSheet()
        }
    }

    private func fetchBook(id: UUID) -> Book? {
        let req = NSFetchRequest<Book>(entityName: "Book")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController(inMemory: true).container.viewContext)
}
#endif
