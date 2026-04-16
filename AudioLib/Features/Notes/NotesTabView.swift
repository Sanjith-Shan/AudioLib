import SwiftUI
import CoreData

struct NotesTabView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NoteDoc.updatedAt, ascending: false)],
        animation: .default
    ) private var notes: FetchedResults<NoteDoc>

    @Environment(\.managedObjectContext) private var context
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if notes.isEmpty {
                    EmptyStateView(
                        iconName: "note.text",
                        title: "No Notes Yet",
                        subtitle: "Tap + to create your first note"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(notes) { note in
                                NavigationLink(value: note) {
                                    NoteRow(note: note)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, Theme.Spacing.md)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.sm)
                    }
                }
            }
            .background(Theme.Colors.white)
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let note = NoteStore.create(title: "Untitled", in: context)
                        path.append(note)
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.Colors.dark)
                    }
                }
            }
            .navigationDestination(for: NoteDoc.self) { note in
                NoteEditorView(note: note)
            }
        }
    }
}
