import SwiftUI
import CoreData

struct DownloadRow: View {
    @ObservedObject var job: DownloadJob
    @ObservedObject private var manager = DownloadManager.shared

    // Local clock used to decide whether a "fetching-metadata" job has been
    // stuck long enough to surface a timeout error even if the manager's
    // downstream timeout hasn't already updated Core Data.
    @State private var now: Date = Date()
    private let tick = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                badge

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayTitle)
                        .font(.ui(15, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                        .lineLimit(1)
                        .padding(.trailing, 24)

                    HStack(spacing: 0) {
                        Text(stateLabel)
                            .font(.ui(12, weight: .medium))
                            .foregroundStyle(stateColor)
                        if let suffix = sourceSuffix {
                            Text(" · \(suffix)")
                                .font(.ui(12))
                                .foregroundStyle(Theme.Colors.inkMute)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .overlay(alignment: .topTrailing) {
                if let bookID = activeBookID {
                    Button {
                        withAnimation { manager.cancelDownload(bookID: bookID) }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.Colors.inkSoft)
                            .frame(width: 24, height: 24)
                            .background(Theme.Colors.inkFaint)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Cancel download")
                }
            }
            .onReceive(tick) { now = $0 }

            // Progress + stats
            if job.state == "downloading" || job.state == "finalizing" {
                ProgressView(value: job.progress)
                    .tint(Theme.Colors.ink)
                    .padding(.top, 12)

                if let active = activeDownload {
                    HStack {
                        Text(sizeLine(active))
                        Spacer()
                        Text(speedEtaLine(active))
                    }
                    .font(.mono(11.5))
                    .foregroundStyle(Theme.Colors.inkSoft)
                    .padding(.top, 8)
                }
            }

            // Error pill
            if job.state == "failed", let msg = job.errorMessage, !msg.isEmpty {
                errorPill(msg)
            } else if job.state == "fetching-metadata", now.timeIntervalSince(job.createdAt) > 30 {
                errorPill("Could not reach YouTube after 30s. Check your connection and try again.")
            }

            // Tap to listen
            if (job.state == "downloading" || job.state == "finalizing"),
               let active = activeDownload,
               active.isStreamingReady,
               active.metadata.fileExtension.lowercased() == "m4a" {
                Button {
                    startStreamingPlayback(active: active)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                        Text("Tap to listen")
                            .font(.ui(12.5, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Colors.tealInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Theme.Colors.tealSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .accessibilityLabel("Start listening now")
            }
        }
        .padding(14)
        .background(Theme.Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
    }

    // MARK: - Leading state badge

    private var badge: some View {
        let isError = job.state == "failed"
        let isDone = job.state == "done"
        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isError ? Theme.Colors.red.opacity(0.1)
                      : isDone ? Theme.Colors.tealSoft
                      : Theme.Colors.cardSoft)
                .frame(width: 36, height: 36)
            Image(systemName: isError ? "wifi.exclamationmark"
                  : isDone ? "checkmark.circle.fill"
                  : "arrow.down.circle")
                .font(.system(size: isDone ? 20 : 18, weight: .regular))
                .foregroundStyle(isError ? Theme.Colors.red
                                 : isDone ? Theme.Colors.teal
                                 : Theme.Colors.ink)
        }
    }

    private func errorPill(_ message: String) -> some View {
        Text(message)
            .font(.ui(12.5))
            .foregroundStyle(Theme.Colors.red)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Theme.Colors.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.top, 10)
    }

    // MARK: - Active download lookup

    private var activeDownload: ActiveDownload? {
        manager.activeDownloads.values.first { $0.jobID == job.id }
    }

    private var activeBookID: UUID? { activeDownload?.bookID }

    // MARK: - Derived display values

    private var displayTitle: String {
        if let title = activeDownload?.metadata.title, !title.isEmpty {
            return title
        }
        let src = job.sourceURL
        if let components = URLComponents(string: src),
           let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
            return videoID
        }
        if let url = URL(string: src), url.host == "youtu.be" {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !id.isEmpty { return id }
        }
        return src
    }

    private var stateLabel: String {
        switch job.state {
        case "queued":            return "Queued"
        case "fetching-metadata": return "Fetching info…"
        case "downloading":
            let pct = Int(job.progress * 100)
            switch activeDownload?.downloadPhase {
            case .macDownloading: return "Mac downloading… \(pct)%"
            case .transferring:   return "Transferring to iPhone… \(pct)%"
            default:              return "Downloading \(pct)%"
            }
        case "finalizing":        return "Finalizing…"
        case "done":              return "Done"
        case "failed":            return "Failed"
        case "cancelled":         return "Cancelled"
        default:                  return job.state
        }
    }

    private var stateColor: Color {
        switch job.state {
        case "queued":            return Theme.Colors.inkMute
        case "fetching-metadata": return Theme.Colors.teal
        case "downloading", "finalizing": return Theme.Colors.ink
        case "done":              return Theme.Colors.teal
        case "failed":            return Theme.Colors.red
        case "cancelled":         return Theme.Colors.inkMute
        default:                  return Theme.Colors.inkMute
        }
    }

    private var sourceSuffix: String? {
        switch activeDownload?.downloadPhase {
        case .macDownloading, .transferring: return "Companion"
        default: break
        }
        if let ext = activeDownload?.metadata.fileExtension.lowercased(), ext == "m4a" {
            return "m4a"
        }
        return nil
    }

    private func speedEtaLine(_ active: ActiveDownload) -> String {
        let speed = speedLine(active)
        let eta = etaLine(active)
        if !speed.isEmpty && !eta.isEmpty { return "\(speed) · \(eta)" }
        return eta.isEmpty ? speed : eta
    }

    private func speedLine(_ active: ActiveDownload) -> String {
        let mbps = active.speedBytesPerSec / 1_000_000
        if mbps >= 1.0 {
            return String(format: "%.1f MB/s", mbps)
        } else if active.speedBytesPerSec >= 1024 {
            return String(format: "%.0f KB/s", active.speedBytesPerSec / 1024)
        } else {
            return ""
        }
    }

    private func etaLine(_ active: ActiveDownload) -> String {
        guard let eta = active.eta, eta.isFinite, eta > 0 else { return "" }
        let seconds = Int(eta)
        if seconds < 60 { return "~\(seconds)s left" }
        let minutes = (seconds + 30) / 60
        if minutes < 60 { return "~\(minutes) min left" }
        let hours = minutes / 60
        let mins = minutes % 60
        return "~\(hours)h \(mins)m left"
    }

    private func sizeLine(_ active: ActiveDownload) -> String {
        let downMB = Double(active.bytesDownloaded) / 1_000_000
        let totalMB = Double(active.bytesTotal) / 1_000_000
        if totalMB > 0 {
            return String(format: "Downloaded %.0f MB of %.0f MB", downMB, totalMB)
        } else if downMB > 0 {
            return String(format: "Downloaded %.0f MB", downMB)
        } else {
            return ""
        }
    }

    private func startStreamingPlayback(active: ActiveDownload) {
        let ext = active.metadata.fileExtension.isEmpty ? "m4a" : active.metadata.fileExtension
        let partialURL = FileStore.audioURL(for: active.bookID, fileExtension: ext)

        let ctx = PersistenceController.shared.container.viewContext
        let req = NSFetchRequest<Book>(entityName: "Book")
        req.predicate = NSPredicate(format: "id == %@", active.bookID as CVarArg)
        guard let book = (try? ctx.fetch(req))?.first else { return }

        PlayerController.shared.playFromPartialFile(
            book: book,
            partialURL: partialURL,
            expectedDuration: active.metadata.durationSeconds
        )
    }
}
