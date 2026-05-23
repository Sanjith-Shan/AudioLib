import SwiftUI

struct LibraryRow: View {
    @ObservedObject var book: Book
    let onPlay: () -> Void

    private var isFinished: Bool { book.durationSeconds > 0 && book.progressFraction >= 0.999 }

    private var remainingLabel: String {
        if isFinished { return "Finished" }
        if book.progressSeconds <= 0 { return "New" }
        return DurationFormatter.string(from: max(0, book.durationSeconds - book.progressSeconds)) + " left"
    }

    var body: some View {
        HStack(spacing: 12) {
            CoverArtView(book: book, size: 64, cornerRadius: Theme.Radius.cover)

            VStack(alignment: .leading, spacing: 1) {
                Text(book.title)
                    .font(.ui(15, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)

                if let author = book.author {
                    Text(author)
                        .font(.ui(13))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .lineLimit(1)
                }

                if let series = book.series, !series.isEmpty {
                    let label = book.seriesIndex > 0 ? "\(series) #\(book.seriesIndex)" : series
                    Text(label)
                        .font(.ui(11.5, weight: .semibold))
                        .foregroundStyle(Theme.Colors.tealInk)
                        .lineLimit(1)
                        .padding(.top, 1)
                }

                HStack(spacing: 8) {
                    ProgressBarView(
                        value: book.progressFraction,
                        height: 2.5,
                        color: isFinished ? Theme.Colors.teal : Theme.Colors.ink
                    )
                    Text(remainingLabel)
                        .font(.mono(11))
                        .foregroundStyle(Theme.Colors.inkMute)
                        .frame(minWidth: 56, alignment: .trailing)
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onPlay) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(width: 38, height: 38)
                    .background(Theme.Colors.cardSoft)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(book.title)")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, 10)
    }
}

/// Thin rounded progress bar used in rows and banners.
struct ProgressBarView: View {
    let value: Double
    var height: CGFloat = 3
    var color: Color = Theme.Colors.teal
    var track: Color = Theme.Colors.inkFaint

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(color)
                    .frame(width: geo.size.width * CGFloat(max(0, min(1, value))))
            }
        }
        .frame(height: height)
    }
}
