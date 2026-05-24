#if os(macOS)
import SwiftUI

// Phase 6 replaces this with the two-pane list + editor layout.
struct MacNotesView: View {
    var model: MacAppModel
    var body: some View {
        VStack(spacing: 0) {
            MToolbar(title: "Notes")
            NotesTabView()
        }
    }
}
#endif
