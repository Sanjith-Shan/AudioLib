import SwiftUI
import CoreData

struct ContentView: View {
    @State private var router = AppRouter.shared

    var body: some View {
        ZStack(alignment: .bottom) {
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
            .tint(Theme.Colors.blue)
            .sheet(isPresented: Bindable(router).showingPlayer) {
                if let bookID = router.currentBookID,
                   let book = fetchBook(id: bookID) {
                    PlayerView(book: book)
                        .environment(router)
                }
            }

            // MiniPlayer above tab bar
            VStack(spacing: 0) {
                MiniPlayer()
                    .environment(router)
                Spacer().frame(height: 49 + safeAreaBottom)
            }
        }
        .environment(router)
    }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }

    private func fetchBook(id: UUID) -> Book? {
        let context = PersistenceController.shared.container.viewContext
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
