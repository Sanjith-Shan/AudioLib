#if os(macOS)
import SwiftUI

/// Per-view top toolbar (50pt): Georgia title + optional subtitle + trailing actions.
struct MToolbar<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: -1) {
                Text(title)
                    .font(.serif(18, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.ui(11.5))
                        .foregroundStyle(Theme.Colors.inkSoft)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 20)
        .frame(height: 50)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.Colors.hair).frame(height: 0.5)
        }
    }
}

extension MToolbar where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// 28pt toolbar button — default / primary (ink) / active (teal) variants.
struct MIconButton: View {
    let systemImage: String
    var label: String? = nil
    var primary = false
    var active = false
    var help: String? = nil
    let action: () -> Void

    @State private var hovering = false

    private var fg: Color { primary ? Theme.Colors.paperFg : active ? Theme.Colors.tealInk : Theme.Colors.ink }
    private var bg: Color {
        if primary { return Theme.Colors.ink }
        if active { return Theme.Colors.teal.opacity(0.13) }
        return hovering ? Color.white.opacity(0.9) : Color.white.opacity(0.6)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                if let label {
                    Text(label).font(.ui(12, weight: .semibold))
                }
            }
            .foregroundStyle(fg)
            .padding(.horizontal, label == nil ? 0 : 10)
            .frame(minWidth: 28, minHeight: 28)
            .background(bg)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(primary ? Theme.Colors.ink : Theme.Colors.hair, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(help ?? label ?? "")
    }
}

/// Grid/List style segmented toggle.
struct MSegmented<Value: Hashable>: View {
    @Binding var value: Value
    let options: [(value: Value, systemImage: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { opt in
                let active = opt.value == value
                Button { value = opt.value } label: {
                    Image(systemName: opt.systemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(width: 30, height: 22)
                        .background(active ? Color.white : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .shadow(color: active ? .black.opacity(0.08) : .clear, radius: 1, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Theme.Colors.ink.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}
#endif
