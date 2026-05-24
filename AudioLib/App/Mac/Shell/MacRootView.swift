#if os(macOS)
import SwiftUI
import CoreData

/// The main window shell: sidebar │ content (+ inspector) over a full-width
/// bottom player bar, per the Mac design handoff.
struct MacRootView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var model = MacAppModel.shared
    @State private var router = AppRouter.shared
    @State private var player = PlayerController.shared
    @AppStorage("audiolib.hasOnboarded") private var hasOnboarded = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    if !model.sidebarCollapsed {
                        MacSidebarView(model: model)
                            .environment(\.managedObjectContext, context)
                    }
                    contentColumn
                }
                if player.currentBook != nil {
                    MacPlayerBar(model: model)
                }
            }

            if model.showExpandedPlayer {
                MacNowPlayingExpanded(model: model)
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
            }
        }
        .frame(minWidth: 1080, minHeight: 680)
        .environment(router)
        .environment(model)
        .animation(.easeOut(duration: 0.28), value: model.showExpandedPlayer)
        .sheet(isPresented: Binding(get: { !hasOnboarded }, set: { _ in })) {
            MacOnboarding { hasOnboarded = true }
                .interactiveDismissDisabled(true)
        }
    }

    // MARK: - Content column

    @ViewBuilder
    private var contentColumn: some View {
        VStack(spacing: 0) {
            switch model.selection.pane {
            case .library:
                MacLibraryView(model: model)
                    .environment(router)
                    .environment(\.managedObjectContext, context)
            case .downloads:
                MacDownloadsView()
                    .environment(router)
                    .environment(\.managedObjectContext, context)
            case .notes:
                MacNotesView(model: model)
                    .environment(router)
                    .environment(\.managedObjectContext, context)
            }
        }
        .frame(minWidth: 520, maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.paper)
    }
}
#endif
