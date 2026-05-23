import SwiftUI
import CoreData

struct NotesTabView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NoteDoc.updatedAt, ascending: false)],
        animation: .default
    ) private var notes: FetchedResults<NoteDoc>

    @Environment(\.managedObjectContext) private var context
    @State private var path = NavigationPath()
    @State private var showingSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if notes.isEmpty {
                    EmptyStateView(
                        iconName: "note.text",
                        title: "No Notes Yet",
                        subtitle: "Tap + to create your first note."
                    )
                } else {
                    List {
                        ForEach(notes) { note in
                            ZStack {
                                NoteRow(note: note)
                                NavigationLink(value: note) { EmptyView() }.opacity(0)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, 4)
                        }
                        .onDelete { offsets in
                            offsets.map { notes[$0] }.forEach(context.delete)
                            try? context.save()
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.top, Theme.Spacing.sm, for: .scrollContent)
                }
            }
            .background(Theme.Colors.paper.ignoresSafeArea())
            .navigationTitle("Notes")
            .iOSNavigationBarLargeTitles()
            .toolbar {
                ToolbarItem(placement: .trailingBar) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.Colors.ink)
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .trailingBar) {
                    Button {
                        let note = NoteStore.create(title: "New Note", in: context)
                        path.append(note)
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.Colors.ink)
                    }
                    .accessibilityLabel("New note")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environment(\.managedObjectContext, context)
            }
            .navigationDestination(for: NoteDoc.self) { note in
                NoteEditorView(note: note)
            }
        }
    }
}
