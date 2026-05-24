import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Applies card radius, white card background, 16pt padding.
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - Section header (uppercase eyebrow above grouped cards)

struct SectionHeaderView: View {
    let title: String
    var dark: Bool = false
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.sectionHeader)
                .tracking(0.5)
                .foregroundStyle(dark ? Theme.Colors.dInkSoft : Theme.Colors.inkSoft)
            Spacer()
            if let trailing {
                Text(trailing.uppercased())
                    .font(.sectionHeader)
                    .tracking(0.5)
                    .foregroundStyle(dark ? Theme.Colors.dInkSoft : Theme.Colors.inkSoft)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Grouped card container (white rounded card holding rows)

struct GroupedCard<Content: View>: View {
    var dark: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(dark ? Theme.Colors.dSheetRow : Theme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .padding(.horizontal, Theme.Spacing.md)
    }
}

#if os(iOS)
extension Theme {
    /// Configures global UIKit appearance to match the warm-paper design:
    /// Georgia serif nav titles on a paper background, ink bar items.
    @MainActor static func configureAppearance() {
        let paper = UIColor(Theme.Colors.paper)
        let ink = UIColor(Theme.Colors.ink)

        let largeFont = UIFont(name: "Georgia-Bold", size: 30) ?? .systemFont(ofSize: 30, weight: .bold)
        let inlineFont = UIFont(name: "Georgia-Bold", size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = paper
        nav.shadowColor = .clear
        nav.largeTitleTextAttributes = [
            .foregroundColor: ink,
            .font: largeFont,
            .kern: -0.5,
        ]
        nav.titleTextAttributes = [
            .foregroundColor: ink,
            .font: inlineFont,
        ]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = ink

        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}
#endif
