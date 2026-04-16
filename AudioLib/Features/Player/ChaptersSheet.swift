import SwiftUI

struct ChaptersSheet: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @State private var player = PlayerController.shared

    var sortedChapters: [Chapter] {
        (book.chapters as? Set<Chapter>)?.sorted { $0.startSeconds < $1.startSeconds } ?? []
    }

    var body: some View {
        NavigationStack {
            List(sortedChapters) { chapter in
                Button {
                    player.seek(to: chapter.startSeconds)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chapter.title)
                                .font(.bodySemibold)
                                .foregroundStyle(Theme.Colors.dark)
                            Text(DurationFormatter.format(seconds: chapter.startSeconds))
                                .font(.caption)
                                .foregroundStyle(Theme.Colors.midSlate)
                        }
                        Spacer()
                        if player.currentTime >= chapter.startSeconds &&
                           (chapter.endSeconds == 0 || player.currentTime < chapter.endSeconds) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(Theme.Colors.teal)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Chapters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
