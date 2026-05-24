import SwiftUI
import CoreData

struct BookEditSheet: View {
    @ObservedObject var book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    @State private var title: String = ""
    @State private var author: String = ""
    @State private var series: String = ""
    @State private var seriesIndex: String = ""
    @State private var didInitialize = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    CoverArtView(book: book, size: 120, cornerRadius: 12)
                        .padding(.top, 4)
                        .padding(.bottom, 18)

                    // Metadata card
                    VStack(spacing: 0) {
                        editRow("Title", text: $title, placeholder: "Title")
                        divider
                        editRow("Author", text: $author, placeholder: "Author")
                        divider
                        editRow("Series", text: $series, placeholder: "None")
                        divider
                        editRow("# in series", text: $seriesIndex, placeholder: "—", numeric: true)
                    }
                    .background(Theme.Colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    SectionHeaderView(title: "Danger Zone")

                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                            Text("Delete Book & Audio File")
                                .font(.ui(15, weight: .semibold))
                            Spacer()
                        }
                        .foregroundStyle(Theme.Colors.red)
                        .padding(14)
                        .frame(maxWidth: .infinity)
                        .background(Theme.Colors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Text("Bookmarks and notes for this book will remain.")
                        .font(.ui(12))
                        .foregroundStyle(Theme.Colors.inkMute)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Theme.Colors.paper.ignoresSafeArea())
            .navigationTitle("Edit Book")
            .iOSNavigationBarInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Theme.Colors.teal)
                }
            }
            .onAppear {
                guard !didInitialize else { return }
                title = book.title
                author = book.author ?? ""
                series = book.series ?? ""
                seriesIndex = book.seriesIndex > 0 ? "\(book.seriesIndex)" : ""
                didInitialize = true
            }
            .confirmationDialog(
                "Delete \"\(book.title)\"?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteBook() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the audio file from your device. This cannot be undone.")
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(Theme.Colors.hair).frame(height: 0.5).padding(.leading, 14)
    }

    private func editRow(_ label: String, text: Binding<String>, placeholder: String, numeric: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.ui(14))
                .foregroundStyle(Theme.Colors.inkSoft)
                .frame(width: 90, alignment: .leading)
            TextField(placeholder, text: text)
                .font(.ui(15))
                .foregroundStyle(Theme.Colors.ink)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity)
                #if os(iOS)
                .keyboardType(numeric ? .numberPad : .default)
                #endif
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func save() {
        book.title = title
        book.author = author.isEmpty ? nil : author
        book.series = series.isEmpty ? nil : series
        book.seriesIndex = Int16(seriesIndex) ?? 0
        try? context.save()
        dismiss()
    }

    private func deleteBook() {
        let id = book.id
        PlayerController.shared.stop()
        if AppRouter.shared.currentBookID == id {
            AppRouter.shared.currentBookID = nil
            AppRouter.shared.showingPlayer = false
        }
        FileStore.deleteBook(id: id)
        context.delete(book)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
