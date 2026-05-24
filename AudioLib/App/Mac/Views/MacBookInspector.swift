#if os(macOS)
import SwiftUI
import CoreData

/// Right-rail inspector (340pt): cover, actions, stats, and the chapter list.
struct MacBookInspector: View {
    @ObservedObject var book: Book
    @Bindable var model: MacAppModel
    @Environment(\.managedObjectContext) private var context
    @State private var player = PlayerController.shared
    @State private var editing = false

    private var isCurrent: Bool { player.currentBook?.id == book.id }

    private var chapters: [Chapter] { book.chaptersArray }

    private var activeChapterID: UUID? {
        guard isCurrent, !chapters.isEmpty else { return nil }
        return chapters.last { $0.startSeconds <= player.currentTime + 0.5 }?.id
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack { Spacer(); CoverArtView(book: book, size: 180, cornerRadius: 10); Spacer() }
                    .padding(.bottom, 18)

                Text(book.title).font(.serif(22, weight: .bold)).foregroundStyle(Theme.Colors.ink).lineLimit(3)
                if let author = book.author {
                    Text(author).font(.ui(14)).foregroundStyle(Theme.Colors.inkSoft).padding(.top, 4)
                }

                actionRow.padding(.top, 14)
                statsRow.padding(.top, 18)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)

            Text("CHAPTERS")
                .font(.ui(11, weight: .bold)).tracking(0.5)
                .foregroundStyle(Theme.Colors.inkMute)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22).padding(.top, 18).padding(.bottom, 6)

            if chapters.isEmpty {
                Text("No chapters for this book.")
                    .font(.ui(12)).foregroundStyle(Theme.Colors.inkMute)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(Array(chapters.enumerated()), id: \.element.id) { idx, ch in
                            chapterRow(idx: idx, ch: ch)
                        }
                    }
                    .padding(.horizontal, 14).padding(.bottom, 16)
                }
            }
        }
        .frame(width: 340)
        .background(Color.white.opacity(0.55))
        .background(.regularMaterial)
        .overlay(alignment: .leading) { Rectangle().fill(Theme.Colors.hair).frame(width: 0.5) }
        .sheet(isPresented: $editing) {
            BookEditSheet(book: book).environment(\.managedObjectContext, context)
                .frame(minWidth: 420, minHeight: 520)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            Button { MacPlayback.play(book) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill").font(.system(size: 11))
                    Text(resumeLabel).font(.ui(13, weight: .semibold)).lineLimit(1)
                }
                .foregroundStyle(Theme.Colors.paperFg)
                .frame(maxWidth: .infinity).padding(.vertical, 9)
                .background(Theme.Colors.ink)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }.buttonStyle(.plain)

            squareButton("bookmark") { if isCurrent { player.addBookmark() } }
            Menu {
                Button { editing = true } label: { Label("Edit Info", systemImage: "pencil") }
                Button { revealInFinder() } label: { Label("Show in Finder", systemImage: "folder") }
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 13)).foregroundStyle(Theme.Colors.ink)
                    .frame(width: 36, height: 36)
                    .background(Theme.Colors.ink.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
        }
    }

    private func squareButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 14)).foregroundStyle(Theme.Colors.ink)
                .frame(width: 36, height: 36)
                .background(Theme.Colors.ink.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }.buttonStyle(.plain)
    }

    private var statsRow: some View {
        HStack(spacing: 4) {
            stat("Duration", DurationFormatter.format(seconds: book.durationSeconds))
            stat("Progress", "\(Int(book.progressFraction * 100))%")
            stat("Speed", MacPlayback.rateLabel(book.playbackRate))
        }
        .padding(.vertical, 12).padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.ui(13, weight: .bold)).monospacedDigit().foregroundStyle(Theme.Colors.ink)
            Text(label.uppercased()).font(.ui(10, weight: .semibold)).tracking(0.4).foregroundStyle(Theme.Colors.inkMute)
        }
        .frame(maxWidth: .infinity)
    }

    private func chapterRow(idx: Int, ch: Chapter) -> some View {
        let active = ch.id == activeChapterID
        return Button {
            if !isCurrent { MacPlayback.play(book) }
            player.seek(to: ch.startSeconds)
        } label: {
            HStack(spacing: 10) {
                Group {
                    if active { Image(systemName: "speaker.wave.2.fill").font(.system(size: 12)) }
                    else { Text("\(idx + 1)").font(.ui(11, weight: .semibold)).monospacedDigit() }
                }
                .foregroundStyle(active ? Theme.Colors.teal : Theme.Colors.inkMute)
                .frame(width: 18)
                Text(ch.title).font(.ui(12.5, weight: active ? .semibold : .medium))
                    .foregroundStyle(active ? Theme.Colors.tealInk : Theme.Colors.ink).lineLimit(1)
                Spacer(minLength: 4)
                Text(DurationFormatter.format(seconds: ch.startSeconds))
                    .font(.mono(10.5)).foregroundStyle(active ? Theme.Colors.tealInk : Theme.Colors.inkSoft)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 7).fill(active ? Theme.Colors.teal.opacity(0.13) : .clear))
        }
        .buttonStyle(.plain)
    }

    private var resumeLabel: String {
        if book.progressSeconds <= 0 { return "Play" }
        return "Resume · " + DurationFormatter.string(from: max(0, book.durationSeconds - book.progressSeconds))
    }

    private func revealInFinder() {
        let url = book.audioURL
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
}
#endif
