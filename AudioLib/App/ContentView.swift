import SwiftUI

struct ContentView: View {
    @State private var router = AppRouter.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $router.selectedTab) {
                DownloadTabView()
                    .tabItem {
                        Label("Download", systemImage: "arrow.down.circle")
                    }
                    .tag(0)

                LibraryTabView()
                    .tabItem {
                        Label("Library", systemImage: "books.vertical")
                    }
                    .tag(1)

                NotesTabView()
                    .tabItem {
                        Label("Notes", systemImage: "note.text")
                    }
                    .tag(2)
            }
            .tint(Theme.Colors.blue)

            // MiniPlayerBar placeholder — Phase 4 will fill this in
            EmptyView()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController(inMemory: true).container.viewContext)
}
