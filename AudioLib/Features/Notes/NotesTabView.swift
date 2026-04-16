import SwiftUI

struct NotesTabView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                iconName: "note.text",
                title: "Notes",
                subtitle: "Your notes will appear here"
            )
            .navigationTitle("Notes")
            .background(Theme.Colors.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Phase 6: will open note editor
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.Colors.blue)
                    }
                    .disabled(true)
                }
            }
        }
    }
}

#Preview {
    NotesTabView()
}
