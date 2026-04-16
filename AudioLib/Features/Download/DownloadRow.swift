import SwiftUI
import CoreData

struct DownloadRow: View {
    @ObservedObject var job: DownloadJob

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Text(displayTitle)
                    .font(.bodySemibold)
                    .foregroundStyle(Theme.Colors.dark)
                    .lineLimit(1)

                Spacer()

                Text(stateLabel)
                    .font(.caption)
                    .foregroundStyle(stateColor)
            }

            if job.state == "downloading" || job.state == "finalizing" {
                ProgressView(value: job.progress)
                    .tint(Theme.Colors.teal)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.cardSmall, style: .continuous))
    }

    // MARK: - Derived display values

    private var displayTitle: String {
        let src = job.sourceURL
        // Try to extract a video ID from a YouTube URL for a tidy label
        if let components = URLComponents(string: src),
           let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
            return videoID
        }
        // youtu.be/<id>
        if let url = URL(string: src), url.host == "youtu.be" {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !id.isEmpty { return id }
        }
        // Fallback: show the raw URL (truncated)
        return src
    }

    private var stateLabel: String {
        switch job.state {
        case "queued":            return "Queued"
        case "fetching-metadata": return "Fetching info…"
        case "downloading":
            let pct = Int(job.progress * 100)
            return "\(pct)%"
        case "finalizing":        return "Finalizing…"
        case "done":              return "Done"
        case "failed":            return "Failed"
        default:                  return job.state
        }
    }

    private var stateColor: Color {
        switch job.state {
        case "queued":            return Theme.Colors.coolGray
        case "fetching-metadata": return Theme.Colors.blue
        case "downloading":       return Theme.Colors.teal
        case "finalizing":        return Theme.Colors.teal
        case "done":              return Theme.Colors.teal
        case "failed":            return Theme.Colors.danger
        default:                  return Theme.Colors.midSlate
        }
    }
}
