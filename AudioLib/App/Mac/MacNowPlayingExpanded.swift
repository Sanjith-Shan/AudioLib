#if os(macOS)
import SwiftUI
import CoreData

/// Full-window "Now Playing" — radial blue gradient, big cover, tabbed
/// chapters/bookmarks/notes, scrubber + transport + secondary controls.
struct MacNowPlayingExpanded: View {
    @Bindable var model: MacAppModel
    @Environment(\.managedObjectContext) private var context
    @State private var player = PlayerController.shared
    @State private var tab: Tab = .chapters
    @State private var showSpeed = false
    @State private var showSleep = false

    enum Tab: String, CaseIterable { case chapters = "Chapters", bookmarks = "Bookmarks", notes = "Notes" }

    private var muted: Color { .white.opacity(0.6) }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0x2A4D6F), Color(hex: 0x0E1E33), Color(hex: 0x0A0A12)],
                center: UnitPoint(x: 0.3, y: 0.2), startRadius: 40, endRadius: 1000
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                if let book = player.currentBook {
                    HStack(spacing: 56) {
                        coverColumn(book)
                        tabbedPane(book)
                    }
                    .padding(.horizontal, 56).padding(.top, 20).padding(.bottom, 12)
                    .frame(maxHeight: .infinity)
                    transport
                } else {
                    Spacer()
                    Text("Nothing playing").foregroundStyle(muted)
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSpeed) { SpeedSheet() }
        .sheet(isPresented: $showSleep) { SleepTimerSheet() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            Text("NOW PLAYING").font(.ui(11, weight: .semibold)).tracking(1)
                .foregroundStyle(.white.opacity(0.55))
            HStack {
                Spacer()
                Button { model.showExpandedPlayer = false } label: {
                    Image(systemName: "chevron.down").font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white).frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 7))
                }.buttonStyle(.plain).help("Collapse")
            }
            .padding(.trailing, 16)
        }
        .frame(height: 48)
    }

    // MARK: - Cover column

    private func coverColumn(_ book: Book) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)
            CoverArtView(book: book, size: 360, cornerRadius: 16)
            VStack(spacing: 6) {
                Text(book.title).font(.serif(30, weight: .bold)).foregroundStyle(.white)
                    .multilineTextAlignment(.center).lineLimit(3)
                if let author = book.author {
                    Text(author).font(.ui(16)).foregroundStyle(.white.opacity(0.65))
                }
                if let ch = activeChapter(book) {
                    Text("\(ch.0) · \(ch.1.title)".uppercased())
                        .font(.ui(11, weight: .semibold)).tracking(0.6)
                        .foregroundStyle(.white.opacity(0.4)).padding(.top, 8)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: 420)
            Spacer(minLength: 0)
        }
        .frame(minWidth: 380)
    }

    // MARK: - Tabbed pane

    private func tabbedPane(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Button { tab = t } label: {
                        Text(t.rawValue).font(.ui(12, weight: .semibold))
                            .foregroundStyle(tab == t ? .white : .white.opacity(0.6))
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(tab == t ? Color.white.opacity(0.12) : .clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }.buttonStyle(.plain)
                }
            }
            .padding(3).background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            ScrollView {
                LazyVStack(spacing: 1) {
                    switch tab {
                    case .chapters:  chaptersList(book)
                    case .bookmarks: bookmarksList(book)
                    case .notes:     notesList(book)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func chaptersList(_ book: Book) -> some View {
        let chapters = book.chaptersArray
        if chapters.isEmpty {
            placeholder("No chapters for this book.")
        } else {
            ForEach(Array(chapters.enumerated()), id: \.element.id) { idx, ch in
                let active = activeChapter(book)?.1.id == ch.id
                rowButton(active: active, action: { player.seek(to: ch.startSeconds) }) {
                    Group {
                        if active { Image(systemName: "speaker.wave.2.fill").font(.system(size: 14)) }
                        else { Text("\(idx + 1)").font(.ui(13, weight: .semibold)).monospacedDigit() }
                    }
                    .foregroundStyle(active ? Theme.Colors.teal : .white.opacity(0.4)).frame(width: 22)
                    Text(ch.title).font(.ui(14, weight: active ? .semibold : .medium))
                        .foregroundStyle(active ? Theme.Colors.teal : .white).lineLimit(1)
                    Spacer(minLength: 4)
                    Text(DurationFormatter.format(seconds: ch.startSeconds))
                        .font(.mono(12)).foregroundStyle(active ? Theme.Colors.teal : .white.opacity(0.5))
                }
            }
        }
    }

    @ViewBuilder
    private func bookmarksList(_ book: Book) -> some View {
        let marks = book.bookmarksArray.sorted { $0.timeSeconds < $1.timeSeconds }
        if marks.isEmpty {
            placeholder("No bookmarks yet. Add one from the controls below.")
        } else {
            ForEach(marks, id: \.id) { mark in
                rowButton(active: false, action: { player.seek(to: mark.timeSeconds) }) {
                    Text(DurationFormatter.format(seconds: mark.timeSeconds))
                        .font(.mono(12, weight: .semibold)).foregroundStyle(Theme.Colors.teal)
                        .frame(width: 70, alignment: .leading)
                    Text(mark.note?.isEmpty == false ? mark.note! : "No note")
                        .font(.ui(13)).foregroundStyle(mark.note?.isEmpty == false ? .white : .white.opacity(0.4))
                        .lineLimit(2)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    @ViewBuilder
    private func notesList(_ book: Book) -> some View {
        let linked = linkedNotes(book)
        if linked.isEmpty {
            placeholder("No notes linked to this book.")
        } else {
            ForEach(linked, id: \.objectID) { note in
                rowButton(active: false, action: { openNote(note) }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.value(forKey: "title") as? String ?? "Untitled")
                            .font(.ui(13.5, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(.white.opacity(0.4))
                }
            }
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text).font(.ui(12.5)).foregroundStyle(.white.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
    }

    private func rowButton<C: View>(active: Bool, action: @escaping () -> Void, @ViewBuilder content: () -> C) -> some View {
        Button(action: action) {
            HStack(spacing: 14) { content() }
                .padding(.horizontal, 14).padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(active ? Theme.Colors.teal.opacity(0.18) : .clear))
        }.buttonStyle(.plain)
    }

    // MARK: - Transport

    private var transport: some View {
        VStack(spacing: 22) {
            HStack(spacing: 14) {
                Text(DurationFormatter.format(seconds: player.currentTime))
                    .font(.mono(12)).foregroundStyle(muted).frame(width: 60, alignment: .trailing)
                Slider(value: Binding(
                    get: { player.duration > 0 ? player.currentTime / player.duration : 0 },
                    set: { player.seek(to: $0 * player.duration) }), in: 0...1).tint(.white)
                Text("-\(DurationFormatter.format(seconds: max(0, player.duration - player.currentTime)))")
                    .font(.mono(12)).foregroundStyle(muted).frame(width: 60, alignment: .leading)
            }

            HStack(spacing: 36) {
                iconButton("gobackward.15", size: 26, color: .white.opacity(0.85)) { player.skipBackward() }
                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .semibold)).foregroundStyle(Theme.Colors.ink)
                        .frame(width: 64, height: 64).background(.white).clipShape(Circle())
                        .shadow(color: .black.opacity(0.35), radius: 20, y: 6)
                }.buttonStyle(.plain)
                iconButton("goforward.15", size: 26, color: .white.opacity(0.85)) { player.skipForward() }
            }

            HStack(spacing: 28) {
                secondary("Speed", systemImage: nil, text: MacPlayback.rateLabel(player.playbackRate)) { showSpeed = true }
                secondary(player.isSleepTimerActive ? sleepLabel : "Sleep", systemImage: "moon.fill",
                          active: player.isSleepTimerActive) { showSleep = true }
                secondary("Bookmark", systemImage: "bookmark") { player.addBookmark() }
                secondary("New Note", systemImage: "square.and.pencil") { newLinkedNote() }
            }
        }
        .padding(.horizontal, 56).padding(.top, 8).padding(.bottom, 28)
    }

    private func iconButton(_ symbol: String, size: CGFloat, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: size)).foregroundStyle(color) }
            .buttonStyle(.plain)
    }

    private func secondary(_ label: String, systemImage: String?, text: String? = nil, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Group {
                    if let text { Text(text).font(.ui(13, weight: .bold)).monospacedDigit() }
                    else if let systemImage { Image(systemName: systemImage).font(.system(size: 16)) }
                }
                .foregroundStyle(active ? Theme.Colors.teal : .white.opacity(0.7))
                .frame(width: 52, height: 36)
                .background(active ? Theme.Colors.teal.opacity(0.22) : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(label).font(.ui(11)).monospacedDigit()
                    .foregroundStyle(active ? Theme.Colors.teal : .white.opacity(0.6))
            }
            .frame(minWidth: 70)
        }.buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func activeChapter(_ book: Book) -> (Int, Chapter)? {
        let chapters = book.chaptersArray
        guard !chapters.isEmpty else { return nil }
        if let idx = chapters.lastIndex(where: { $0.startSeconds <= player.currentTime + 0.5 }) {
            return (idx + 1, chapters[idx])
        }
        return nil
    }

    private var sleepLabel: String {
        guard let end = player.sleepTimerEndDate else { return "Sleep" }
        let r = Int(max(0, end.timeIntervalSinceNow))
        return String(format: "%d:%02d", r / 60, r % 60)
    }

    private func linkedNotes(_ book: Book) -> [NSManagedObject] {
        let req = NSFetchRequest<NSManagedObject>(entityName: "NoteDoc")
        req.predicate = NSPredicate(format: "linkedBookID == %@", book.id as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        return (try? context.fetch(req)) ?? []
    }

    private func openNote(_ note: NSManagedObject) {
        model.selection = .notesLinked
        model.showExpandedPlayer = false
    }

    private func newLinkedNote() {
        guard let book = player.currentBook else { return }
        let note = NSEntityDescription.insertNewObject(forEntityName: "NoteDoc", into: context)
        note.setValue(UUID(), forKey: "id")
        note.setValue("Note on \(book.title)", forKey: "title")
        note.setValue(Date(), forKey: "createdAt")
        note.setValue(Date(), forKey: "updatedAt")
        note.setValue(book.id, forKey: "linkedBookID")
        if let rtf = try? NSAttributedString(string: "").data(
            from: NSRange(location: 0, length: 0),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
            note.setValue(rtf, forKey: "rtfData")
        }
        try? context.save()
        model.selection = .notesLinked
        model.showExpandedPlayer = false
    }
}
#endif
