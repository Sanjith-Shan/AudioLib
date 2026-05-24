#if os(macOS)
import SwiftUI

/// Library "List" view — a table with cover/title/author/duration/progress/last-played.
struct MacLibraryList<MenuContent: View>: View {
    let books: [Book]
    let currentID: UUID?
    let onPlay: (Book) -> Void
    let onSelect: (Book) -> Void
    @ViewBuilder let menu: (Book) -> MenuContent

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(books, id: \.id) { book in
                        MacLibraryListRow(book: book, isCurrent: book.id == currentID,
                                          onPlay: { onPlay(book) }, onSelect: { onSelect(book) })
                            .contextMenu { menu(book) }
                        Rectangle().fill(Theme.Colors.hair).frame(height: 0.5)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Color.clear.frame(width: 32)
            Text("Title").frame(maxWidth: .infinity, alignment: .leading).layoutPriority(2)
            Text("Author").frame(maxWidth: .infinity, alignment: .leading).layoutPriority(1)
            Text("Duration").frame(width: 70, alignment: .trailing)
            Text("Progress").frame(width: 120, alignment: .leading)
            Text("Last Played").frame(width: 110, alignment: .leading)
        }
        .font(.ui(10.5, weight: .bold)).tracking(0.5)
        .foregroundStyle(Theme.Colors.inkMute)
        .textCase(.uppercase)
        .padding(.horizontal, 24).padding(.vertical, 8)
        .background(Theme.Colors.paper.opacity(0.94))
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.hair).frame(height: 0.5) }
    }
}

private struct MacLibraryListRow: View {
    @ObservedObject var book: Book
    let isCurrent: Bool
    let onPlay: () -> Void
    let onSelect: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            CoverArtView(book: book, size: 32, cornerRadius: 4)
            Text(book.title).font(.ui(13, weight: .semibold)).foregroundStyle(Theme.Colors.ink)
                .lineLimit(1).frame(maxWidth: .infinity, alignment: .leading).layoutPriority(2)
            Text(book.author ?? "—").font(.ui(12)).foregroundStyle(Theme.Colors.inkSoft)
                .lineLimit(1).frame(maxWidth: .infinity, alignment: .leading).layoutPriority(1)
            Text(DurationFormatter.format(seconds: book.durationSeconds))
                .font(.mono(11)).foregroundStyle(Theme.Colors.inkSoft).frame(width: 70, alignment: .trailing)
            HStack(spacing: 6) {
                ProgressBarView(value: book.progressFraction, height: 3,
                                color: book.progressFraction >= 0.999 ? Theme.Colors.teal : Theme.Colors.ink)
                Text("\(Int(book.progressFraction * 100))%").font(.mono(10.5))
                    .foregroundStyle(Theme.Colors.inkMute).frame(width: 34, alignment: .trailing)
            }
            .frame(width: 120)
            Text(lastPlayed).font(.ui(11)).foregroundStyle(Theme.Colors.inkMute)
                .frame(width: 110, alignment: .leading).lineLimit(1)
        }
        .padding(.horizontal, 24).padding(.vertical, 10)
        .background(isCurrent ? Theme.Colors.teal.opacity(0.07) : (hovering ? Theme.Colors.ink.opacity(0.03) : .clear))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onPlay() }
        .onTapGesture { onSelect() }
        .onHover { hovering = $0 }
    }

    private var lastPlayed: String {
        guard let date = book.lastPlayedAt else { return "Never" }
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .abbreviated
        return fmt.localizedString(for: date, relativeTo: Date())
    }
}
#endif
