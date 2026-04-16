import SwiftUI

struct LibraryRow: View {
    let book: Book
    @Environment(AppRouter.self) private var router

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Cover art
            CoverArtView(book: book, size: 64)

            // Metadata (fills remaining space)
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.bodySemibold)
                    .foregroundStyle(Theme.Colors.dark)
                    .lineLimit(1)

                if let author = book.author {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(Theme.Colors.midSlate)
                        .lineLimit(1)
                }

                // Series info if available
                if let series = book.series, !series.isEmpty {
                    let label = book.seriesIndex > 0 ? "\(series) #\(book.seriesIndex)" : series
                    Text(label)
                        .font(.captionSmall)
                        .foregroundStyle(Theme.Colors.blue)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                // Progress + remaining
                HStack(spacing: Theme.Spacing.xs) {
                    if book.durationSeconds > 0 {
                        ProgressView(value: book.progressFraction)
                            .tint(Theme.Colors.teal)
                            .frame(maxWidth: .infinity)

                        Text(DurationFormatter.remainingString(
                            total: book.durationSeconds,
                            progress: book.progressSeconds
                        ))
                        .font(.captionSmall)
                        .foregroundStyle(Theme.Colors.coolGray)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Play button (44pt circular, blue)
            Button {
                router.currentBookID = book.id
                router.showingPlayer = true
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.Colors.blue)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .frame(height: 80)
        .background(Theme.Colors.white)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.cardSmall))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.cardSmall)
                .stroke(Theme.Colors.grayTone, lineWidth: 0.5)
        )
    }
}
