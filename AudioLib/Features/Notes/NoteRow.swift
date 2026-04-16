import SwiftUI

struct NoteRow: View {
    let note: NoteDoc

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(note.title)
                .font(.bodySemibold)
                .foregroundStyle(Theme.Colors.dark)
                .lineLimit(1)

            HStack {
                Text(note.updatedAt, style: .relative)
                    .font(.captionSmall)
                    .foregroundStyle(Theme.Colors.coolGray)

                if note.linkedBookID != nil {
                    Spacer()
                    Text("Linked")
                        .font(.captionSmall)
                        .foregroundStyle(Theme.Colors.blue)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.white)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.cardSmall))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.cardSmall)
                .stroke(Theme.Colors.grayTone, lineWidth: 0.5)
        )
    }
}
