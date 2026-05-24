#if os(macOS)
import SwiftUI

// Phase 5 replaces this with the spec's add-card + active + completed layout.
struct MacDownloadsView: View {
    var body: some View {
        VStack(spacing: 0) {
            MToolbar(title: "Downloads")
            DownloadTabView()
        }
    }
}
#endif
