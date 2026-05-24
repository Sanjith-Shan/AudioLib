#if os(macOS)
import SwiftUI

/// First-launch onboarding (two-column), shown once via audiolib.hasOnboarded.
struct MacOnboarding: View {
    let onGetStarted: () -> Void

    private let features: [(String, String, String)] = [
        ("bolt.fill", "Faster downloads", "Run companion mode on this Mac to bypass throttling."),
        ("books.vertical.fill", "A library worth owning", "Continue listening, sorted your way."),
        ("clock", "Notes linked to time", "Bookmark thoughts at the exact moment."),
        ("arrow.triangle.2.circlepath", "Continuity with iPhone", "Your place syncs across devices.")
    ]

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.Gradients.appIcon).frame(width: 96, height: 96)
                    .overlay(Image(systemName: "headphones").font(.system(size: 44)).foregroundStyle(Theme.Colors.paperFg))
                    .shadow(color: Color(hex: 0x0F5751, opacity: 0.32), radius: 20, y: 8)
                    .padding(.bottom, 28)
                Text("Welcome to\nAudioLib.")
                    .font(.serif(40, weight: .bold)).foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Turn any YouTube link into an audiobook you actually own — then listen, bookmark, and take notes.")
                    .font(.ui(15)).foregroundStyle(Theme.Colors.inkSoft)
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding(.top, 14)
                Spacer()
                Button(action: onGetStarted) {
                    Text("Get Started").font(.ui(15, weight: .semibold)).foregroundStyle(Theme.Colors.paperFg)
                        .frame(maxWidth: 220).padding(.vertical, 13)
                        .background(Theme.Colors.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Theme.Colors.teal.opacity(0.3), radius: 10, y: 4)
                }.buttonStyle(.plain)
            }
            .padding(48)
            .frame(width: 360, alignment: .leading)

            VStack(spacing: 12) {
                ForEach(Array(features.enumerated()), id: \.offset) { _, f in
                    HStack(spacing: 14) {
                        Image(systemName: f.0).font(.system(size: 16)).foregroundStyle(Theme.Colors.tealInk)
                            .frame(width: 36, height: 36)
                            .background(Theme.Colors.tealSoft).clipShape(RoundedRectangle(cornerRadius: 9))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(f.1).font(.ui(13.5, weight: .semibold)).foregroundStyle(Theme.Colors.ink)
                            Text(f.2).font(.ui(12)).foregroundStyle(Theme.Colors.inkSoft)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.55))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.Colors.hair, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.opacity(0.25))
        }
        .frame(width: 800, height: 560)
        .background(Theme.Gradients.onboarding)
    }
}
#endif
