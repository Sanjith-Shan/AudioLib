import SwiftUI
import CoreData

struct NoteEditorView: View {
    @ObservedObject var note: NoteDoc
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var attributedText: NSAttributedString = NSAttributedString()
    @State private var titleDraft: String = ""
    @State private var saveTask: Task<Void, Never>? = nil
    @State private var titleSaveTask: Task<Void, Never>? = nil

    private var linkedBook: Book? {
        guard let id = note.linkedBookID else { return nil }
        let req = NSFetchRequest<Book>(entityName: "Book")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $titleDraft)
                .font(.serif(26, weight: .bold))
                .foregroundStyle(Theme.Colors.ink)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            if let book = linkedBook {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 12))
                    Text(book.author != nil ? "\(book.title) · \(book.author!)" : book.title)
                        .font(.ui(12, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(Theme.Colors.tealInk)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.Colors.tealSoft)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            RichTextEditor(attributedText: $attributedText, placeholder: "Start writing...")
                .padding(.top, 8)
        }
        .background(Theme.Colors.paper.ignoresSafeArea())
        .iOSNavigationBarInline()
        .toolbar {
            ToolbarItem(placement: .trailingBar) {
                Button {
                    commitTitle()
                    saveNow()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.ui(14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Theme.Colors.teal)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .onAppear {
            titleDraft = note.title
            if let data = note.rtfData {
                attributedText = NoteStore.fromRTF(data) ?? NSAttributedString()
            }
        }
        .onChange(of: titleDraft) { _, newValue in
            titleSaveTask?.cancel()
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            titleSaveTask = Task {
                try? await Task.sleep(nanoseconds: 600_000_000)
                if !Task.isCancelled {
                    await MainActor.run {
                        note.title = trimmed.isEmpty ? "Untitled" : trimmed
                        note.updatedAt = Date()
                        try? context.save()
                    }
                }
            }
        }
        .onChange(of: attributedText) { _, newValue in
            saveTask?.cancel()
            saveTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if !Task.isCancelled {
                    NoteStore.save(note, attributedString: newValue, in: context)
                }
            }
        }
        .onDisappear {
            saveTask?.cancel()
            titleSaveTask?.cancel()
            commitTitle()
            saveNow()
        }
    }

    private func commitTitle() {
        let trimmed = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        note.title = trimmed.isEmpty ? "Untitled" : trimmed
        note.updatedAt = Date()
    }

    private func saveNow() {
        NoteStore.save(note, attributedString: attributedText, in: context)
    }
}
