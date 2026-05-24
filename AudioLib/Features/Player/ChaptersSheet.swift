import SwiftUI

struct ChaptersSheet: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var player = PlayerController.shared

    var sortedChapters: [Chapter] {
        (book.chapters as? Set<Chapter>)?.sorted { $0.startSeconds < $1.startSeconds } ?? []
    }

    private func isActive(_ chapter: Chapter) -> Bool {
        player.currentTime >= chapter.startSeconds &&
        (chapter.endSeconds == 0 || player.currentTime < chapter.endSeconds)
    }

    var body: some View {
        VStack(spacing: 0) {
            DarkSheetHeader(title: "Chapters") { dismiss() }

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(sortedChapters.enumerated()), id: \.element.objectID) { index, chapter in
                        let active = isActive(chapter)
                        Button {
                            player.seek(to: chapter.startSeconds)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    if active {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Theme.Colors.teal)
                                    } else {
                                        Text("\(index + 1)")
                                            .font(.mono(13, weight: .semibold))
                                            .foregroundStyle(Theme.Colors.dInkMute)
                                    }
                                }
                                .frame(width: 22, height: 22)

                                Text(chapter.title)
                                    .font(.ui(14.5, weight: active ? .semibold : .medium))
                                    .foregroundStyle(active ? Theme.Colors.teal : .white)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(DurationFormatter.format(seconds: chapter.startSeconds))
                                    .font(.mono(12))
                                    .foregroundStyle(active ? Theme.Colors.teal : Theme.Colors.dInkSoft)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(active ? Theme.Colors.teal.opacity(0.13) : Color.clear)
                        }
                        .buttonStyle(.plain)

                        if index < sortedChapters.count - 1 {
                            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
                                .padding(.leading, 14)
                        }
                    }
                }
                .background(Theme.Colors.dSheetRow)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
