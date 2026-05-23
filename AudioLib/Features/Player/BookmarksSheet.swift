import SwiftUI
import CoreData

struct BookmarksSheet: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @State private var player = PlayerController.shared

    var sortedBookmarks: [Bookmark] {
        (book.bookmarks as? Set<Bookmark>)?.sorted { $0.timeSeconds < $1.timeSeconds } ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            DarkSheetHeader(title: "Bookmarks") { dismiss() }

            ScrollView {
                VStack(spacing: 0) {
                    Button {
                        player.addBookmark()
                        Haptics.success()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 16))
                            Text("Bookmark this position · \(DurationFormatter.format(seconds: player.currentTime))")
                                .font(.ui(15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.Colors.teal)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Theme.Colors.teal.opacity(0.3), radius: 14, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 16)

                    if sortedBookmarks.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(Theme.Colors.dInkMute)
                            Text("No Bookmarks")
                                .font(.ui(16, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("Tap the button above to save where you are.")
                                .font(.ui(13))
                                .foregroundStyle(Theme.Colors.dInkSoft)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(sortedBookmarks.enumerated()), id: \.element.objectID) { index, bookmark in
                                Button {
                                    player.seek(to: bookmark.timeSeconds)
                                    dismiss()
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        Text(DurationFormatter.format(seconds: bookmark.timeSeconds))
                                            .font(.mono(13, weight: .semibold))
                                            .foregroundStyle(Theme.Colors.teal)
                                        Text((bookmark.note?.isEmpty == false) ? bookmark.note! : "No note")
                                            .font(.ui(14))
                                            .foregroundStyle((bookmark.note?.isEmpty == false) ? .white : Theme.Colors.dInkMute)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(14)
                                }
                                .buttonStyle(.plain)

                                if index < sortedBookmarks.count - 1 {
                                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
                                        .padding(.leading, 14)
                                }
                            }
                        }
                        .background(Theme.Colors.dSheetRow)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Theme.Colors.dSheet.ignoresSafeArea())
        .preferredColorScheme(.dark)
        #if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.Colors.dSheet)
        #endif
    }
}
