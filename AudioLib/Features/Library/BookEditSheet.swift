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

    var body: some View {
        NavigationStack {
            Form {
                Section("Metadata") {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Series", text: $series)
                    TextField("# in Series", text: $seriesIndex)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                title = book.title
                author = book.author ?? ""
                series = book.series ?? ""
                seriesIndex = book.seriesIndex > 0 ? "\(book.seriesIndex)" : ""
            }
        }
    }

    private func save() {
        book.title = title
        book.author = author.isEmpty ? nil : author
        book.series = series.isEmpty ? nil : series
        book.seriesIndex = Int16(seriesIndex) ?? 0
        try? context.save()
        dismiss()
    }
}
