#if os(macOS)
import SwiftUI
import CoreData

struct MacSidebarView: View {
    @Bindable var model: MacAppModel

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)])
    private var books: FetchedResults<Book>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "updatedAt", ascending: false)],
                  animation: .default)
    private var notes: FetchedResults<NoteDoc>

    @ObservedObject private var downloads = DownloadManager.shared

    // MARK: - Derived counts

    private var continueCount: Int {
        books.filter { $0.lastPlayedAt != nil && $0.progressSeconds > 0 && $0.progressFraction < 0.99 }.count
    }
    private var recentCount: Int {
        let cutoff = Date().addingTimeInterval(-14 * 86_400)
        return books.filter { $0.dateAdded > cutoff }.count
    }
    private var finishedCount: Int {
        books.filter { $0.durationSeconds > 0 && $0.progressFraction >= 0.99 }.count
    }
    private var linkedNotesCount: Int {
        notes.filter { $0.linkedBookID != nil }.count
    }
    private var seriesNames: [String] {
        let names = books.compactMap { $0.series }.filter { !$0.isEmpty }
        return Array(Set(names)).sorted()
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 38)   // real traffic lights overlay here

            branding

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header("Library")
                    item(.allBooks, count: books.count)
                    item(.continueListening, count: continueCount)
                    item(.recentlyAdded, count: recentCount)
                    item(.finished, count: finishedCount)

                    header("Downloads")
                    item(.downloadsActive, label: "Active", count: downloads.activeDownloads.count)
                    item(.downloadsCompleted, label: "Completed", count: nil)

                    header("Notes")
                    item(.notesAll, label: "All Notes", count: notes.count)
                    item(.notesLinked, label: "Linked to Books", count: linkedNotesCount)

                    if !seriesNames.isEmpty {
                        header("Series")
                        ForEach(seriesNames, id: \.self) { name in
                            item(.series(name), label: name, count: nil)
                        }
                    }
                }
                .padding(.bottom, 8)
            }

            footer
        }
        .frame(width: 232)
        .background(Theme.Colors.paperAlt.opacity(0.62))
        .background(.regularMaterial)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Theme.Colors.hair).frame(width: 0.5)
        }
    }

    // MARK: - Branding

    private var branding: some View {
        HStack(spacing: 9) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Theme.Gradients.appIcon)
                .frame(width: 26, height: 26)
                .overlay(
                    Image(systemName: "headphones")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.paperFg)
                )
            Text("AudioLib")
                .font(.serif(17, weight: .bold))
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    // MARK: - Rows

    private func header(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.ui(10.5, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(Theme.Colors.inkMute)
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func item(_ section: MacSection, label: String? = nil, count: Int?) -> some View {
        MacSidebarRow(
            systemImage: section.systemImage,
            label: label ?? section.title,
            count: count,
            selected: model.selection == section
        ) {
            model.selection = section
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.Colors.teal)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(Theme.Colors.teal.opacity(0.18), lineWidth: 3))
                    Text("Companion mode")
                        .font(.ui(11, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                }
                Text(companionEndpoint)
                    .font(.mono(10.5))
                    .foregroundStyle(Theme.Colors.inkSoft)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            SettingsLink {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                    Text("Preferences…")
                        .font(.ui(12, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(Theme.Colors.inkSoft)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.Colors.hair).frame(height: 0.5)
        }
    }

    private var companionEndpoint: String {
        let host = UserDefaults.standard.string(forKey: "audiolib.companionHost") ?? "localhost"
        let port = UserDefaults.standard.integer(forKey: "audiolib.companionPort")
        return "\(host):\(port == 0 ? 8787 : port)"
    }
}

private struct MacSidebarRow: View {
    let systemImage: String
    let label: String
    let count: Int?
    let selected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(selected ? Theme.Colors.teal : Theme.Colors.inkSoft)
                    .frame(width: 16)
                Text(label)
                    .font(.ui(12.5, weight: .medium))
                    .foregroundStyle(selected ? Theme.Colors.tealInk : Theme.Colors.ink)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if let count {
                    Text("\(count)")
                        .font(.ui(11, weight: .medium))
                        .foregroundStyle(selected ? Theme.Colors.tealInk : Theme.Colors.inkMute)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(selected ? Theme.Colors.teal.opacity(0.13)
                          : hovering ? Color.white.opacity(0.3) : .clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { hovering = $0 }
    }
}
#endif
