#if os(macOS)
import SwiftUI
import CoreData

/// Two-pane Notes: list on the left, rich editor on the right.
struct MacNotesView: View {
    @Bindable var model: MacAppModel
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NoteDoc.updatedAt, ascending: false)],
        animation: .default
    ) private var notes: FetchedResults<NoteDoc>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Book.title, ascending: true)])
    private var books: FetchedResults<Book>

    @State private var player = PlayerController.shared
    @State private var selectedID: UUID?
    @State private var searchText = ""
    @State private var titleText = ""
    @State private var attributed = NSAttributedString(string: "")
    @State private var savedAt: Date?

    private var linkedOnly: Bool { model.selection == .notesLinked }

    private var filtered: [NoteDoc] {
        notes.filter { note in
            (!linkedOnly || note.linkedBookID != nil) &&
            (searchText.isEmpty || note.title.localizedCaseInsensitiveContains(searchText))
        }
    }

    private var selectedNote: NoteDoc? { notes.first { $0.id == selectedID } }

    private var linkedBook: Book? {
        guard let id = selectedNote?.linkedBookID else { return nil }
        return books.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 0) {
            MToolbar(title: "Notes", subtitle: "\(notes.count) notes · \(notes.filter { $0.linkedBookID != nil }.count) linked") {
                MIconButton(systemImage: "plus", label: "New Note", primary: true) { newNote() }
            }
            HStack(spacing: 0) {
                listPane
                Divider()
                editorPane
            }
        }
        .background(Theme.Colors.paper)
        .onAppear { if selectedID == nil { selectFirst() } }
        .onChange(of: selectedID) { _, _ in loadSelection() }
    }

    // MARK: - List pane

    private var listPane: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.system(size: 12)).foregroundStyle(Theme.Colors.inkSoft)
                TextField("Search notes", text: $searchText).textFieldStyle(.plain).font(.ui(12))
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Color.white.opacity(0.7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.Colors.ink.opacity(0.06), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filtered, id: \.id) { note in
                        noteRow(note)
                        Rectangle().fill(Theme.Colors.hair).frame(height: 0.5)
                    }
                }
            }
        }
        .frame(width: 320)
        .background(Theme.Colors.paper)
    }

    private func noteRow(_ note: NoteDoc) -> some View {
        let selected = note.id == selectedID
        return Button { selectedID = note.id } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.ui(13.5, weight: .semibold)).foregroundStyle(Theme.Colors.ink).lineLimit(1)
                    Spacer(minLength: 6)
                    Text(relative(note.updatedAt)).font(.ui(10.5)).foregroundStyle(Theme.Colors.inkMute)
                }
                Text(snippet(note)).font(.ui(11.5)).foregroundStyle(Theme.Colors.inkSoft)
                    .lineLimit(2).multilineTextAlignment(.leading)
                if note.linkedBookID != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "link").font(.system(size: 8, weight: .bold))
                        Text("LINKED").font(.ui(10, weight: .bold)).tracking(0.3)
                    }
                    .foregroundStyle(Theme.Colors.tealInk)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Theme.Colors.tealSoft).clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 10).padding(.trailing, 16).padding(.leading, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Theme.Colors.teal.opacity(0.08) : .clear)
            .overlay(alignment: .leading) {
                Rectangle().fill(selected ? Theme.Colors.teal : .clear).frame(width: 3)
            }
        }.buttonStyle(.plain)
    }

    // MARK: - Editor pane

    @ViewBuilder
    private var editorPane: some View {
        if selectedNote == nil {
            VStack(spacing: 8) {
                Image(systemName: "note.text").font(.system(size: 34)).foregroundStyle(Theme.Colors.inkMute)
                Text("Select or create a note").font(.ui(13)).foregroundStyle(Theme.Colors.inkSoft)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: 0xFFFDF7).opacity(0.4))
        } else {
            VStack(spacing: 0) {
                editorToolbar
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Title", text: $titleText)
                        .textFieldStyle(.plain)
                        .font(.serif(32, weight: .bold))
                        .foregroundStyle(Theme.Colors.ink)
                        .onChange(of: titleText) { _, _ in save() }
                    if let book = linkedBook {
                        HStack(spacing: 6) {
                            Image(systemName: "link").font(.system(size: 11))
                            Text("\(book.title)\(book.author.map { " · \($0)" } ?? "")")
                                .font(.ui(11.5, weight: .semibold))
                        }
                        .foregroundStyle(Theme.Colors.tealInk)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.Colors.tealSoft).clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    RichTextEditor(attributedText: $attributed)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onChange(of: attributed) { _, _ in save() }
                }
                .padding(.horizontal, 40).padding(.top, 20).padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: 0xFFFDF7).opacity(0.4))
        }
    }

    private var editorToolbar: some View {
        HStack(spacing: 4) {
            fmtButton("bold") { MacTextFormatting.toggleTrait(.boldFontMask) }
            fmtButton("italic") { MacTextFormatting.toggleTrait(.italicFontMask) }
            fmtButton("underline") { MacTextFormatting.toggleUnderline() }
            fmtDivider
            fmtButton("textformat.size.larger") { MacTextFormatting.applyHeading(size: 24) }
            fmtButton("textformat.size") { MacTextFormatting.applyHeading(size: 18) }
            fmtDivider
            fmtButton("list.bullet") { MacTextFormatting.insertLinePrefix("• ") }
            fmtButton("list.number") { MacTextFormatting.insertLinePrefix("1. ") }
            fmtDivider
            Button { insertTimestamp() } label: {
                HStack(spacing: 5) {
                    Image(systemName: "clock").font(.system(size: 12))
                    Text("Insert · \(DurationFormatter.format(seconds: player.currentTime))")
                        .font(.ui(11, weight: .semibold)).monospacedDigit()
                }
                .foregroundStyle(Theme.Colors.tealInk)
                .padding(.horizontal, 10).frame(height: 28)
                .background(Theme.Colors.tealSoft).clipShape(RoundedRectangle(cornerRadius: 6))
            }.buttonStyle(.plain)
            Spacer()
            Text(savedLabel).font(.ui(11)).foregroundStyle(Theme.Colors.inkMute)
        }
        .padding(.horizontal, 16).frame(height: 42)
        .background(Color.white.opacity(0.4))
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.hair).frame(height: 0.5) }
    }

    private func fmtButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 13)).foregroundStyle(Theme.Colors.ink)
                .frame(width: 28, height: 28)
        }.buttonStyle(.plain)
    }
    private var fmtDivider: some View {
        Rectangle().fill(Theme.Colors.ink.opacity(0.12)).frame(width: 1, height: 20).padding(.horizontal, 4)
    }

    // MARK: - Data

    private func selectFirst() { selectedID = filtered.first?.id; loadSelection() }

    private func loadSelection() {
        guard let note = selectedNote else { titleText = ""; attributed = NSAttributedString(string: ""); return }
        titleText = note.title
        if let data = note.rtfData,
           let s = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            attributed = s
        } else {
            attributed = NSAttributedString(string: "")
        }
        savedAt = note.updatedAt
    }

    private func save() {
        guard let note = selectedNote else { return }
        note.title = titleText
        note.rtfData = try? attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        note.updatedAt = Date()
        try? context.save()
        savedAt = note.updatedAt
    }

    private func newNote() {
        let note = NoteDoc(context: context)
        note.id = UUID()
        note.title = "New Note"
        note.createdAt = Date()
        note.updatedAt = Date()
        if linkedOnly, let bookID = player.currentBook?.id { note.linkedBookID = bookID }
        note.rtfData = try? NSAttributedString(string: "").data(
            from: NSRange(location: 0, length: 0),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        try? context.save()
        selectedID = note.id
        loadSelection()
    }

    private func insertTimestamp() {
        let t = DurationFormatter.format(seconds: player.currentTime)
        let title = player.currentBook?.title
        MacTextFormatting.insert("[\(title.map { "\($0) @ " } ?? "")\(t)] ")
    }

    // MARK: - Helpers

    private func snippet(_ note: NoteDoc) -> String {
        guard let data = note.rtfData,
              let s = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        else { return " " }
        return s.string.isEmpty ? " " : s.string
    }

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter(); f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    private var savedLabel: String {
        guard savedAt != nil else { return "" }
        return "Last saved · just now"
    }
}
#endif
