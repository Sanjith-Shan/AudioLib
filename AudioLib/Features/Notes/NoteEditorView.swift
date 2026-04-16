import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var note: NoteDoc
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var attributedText: NSAttributedString = NSAttributedString()
    @State private var saveTask: Task<Void, Never>? = nil

    var body: some View {
        RichTextEditor(attributedText: $attributedText, placeholder: "Start writing...")
            .background(Theme.Colors.white)
            .navigationTitle(note.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveNow()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let data = note.rtfData {
                    attributedText = NoteStore.fromRTF(data) ?? NSAttributedString()
                }
            }
            .onChange(of: attributedText) { _, newValue in
                // Autosave debounced — cancel previous, schedule new
                saveTask?.cancel()
                saveTask = Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2s debounce
                    if !Task.isCancelled {
                        NoteStore.save(note, attributedString: newValue, in: context)
                    }
                }
            }
            .onDisappear {
                saveTask?.cancel()
                saveNow()
            }
    }

    private func saveNow() {
        NoteStore.save(note, attributedString: attributedText, in: context)
    }
}
