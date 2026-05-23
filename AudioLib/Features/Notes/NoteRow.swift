import SwiftUI

struct NoteRow: View {
    let note: NoteDoc

    private var isLinked: Bool { note.linkedBookID != nil }

    private var snippet: String? {
        guard let data = note.rtfData,
              let attr = NoteStore.fromRTF(data) else { return nil }
        let text = attr.string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        return text.isEmpty ? nil : text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isLinked ? Theme.Colors.teal : Theme.Colors.inkFaint)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(note.title)
                        .font(.ui(16, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isLinked {
                        Text("LINKED")
                            .font(.ui(10, weight: .bold))
                            .tracking(0.3)
                            .foregroundStyle(Theme.Colors.tealInk)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.tealSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }

                if let snippet {
                    Text(snippet)
                        .font(.ui(13.5))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .lineLimit(1)
                        .lineSpacing(2)
                        .padding(.top, 3)
                }

                Text(note.updatedAt, style: .relative)
                    .font(.ui(12))
                    .foregroundStyle(Theme.Colors.inkMute)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.card)
    }
}
