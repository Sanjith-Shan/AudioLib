import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - Platform image typealias

#if os(iOS)
typealias PlatformImage = UIImage
#else
typealias PlatformImage = NSImage
#endif

// MARK: - PlatformImage → platform-native type for MediaPlayer

extension PlatformImage {
    #if os(iOS)
    var platformUIImage: UIImage { self }
    #else
    var platformUIImage: NSImage { self }
    #endif
}

// MARK: - SwiftUI Image init from PlatformImage

extension Image {
    init(platformImage: PlatformImage) {
        #if os(iOS)
        self.init(uiImage: platformImage)
        #else
        self.init(nsImage: platformImage)
        #endif
    }
}

// MARK: - Cross-platform ToolbarItemPlacement shims

extension ToolbarItemPlacement {
    /// .topBarTrailing on iOS; .automatic on macOS.
    static var trailingBar: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarTrailing
        #else
        return .automatic
        #endif
    }

    /// .topBarLeading on iOS; .cancellationAction on macOS.
    static var leadingBar: ToolbarItemPlacement {
        #if os(iOS)
        return .topBarLeading
        #else
        return .cancellationAction
        #endif
    }
}

// MARK: - iOS-only modifier no-ops

extension View {
    /// Applies toolbar background modifiers (nav bar + tab bar) on iOS only.
    func iOSToolbarBackgrounds(_ color: Color) -> some View {
        #if os(iOS)
        return self
            .toolbarBackground(color, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(color, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        #else
        return self
        #endif
    }

    /// Applies .navigationBarTitleDisplayMode(.large) on iOS only.
    func iOSNavigationBarLargeTitles() -> some View {
        #if os(iOS)
        return self.navigationBarTitleDisplayMode(.large)
        #else
        return self
        #endif
    }

    /// Applies .navigationBarTitleDisplayMode(.inline) on iOS only.
    func iOSNavigationBarInline() -> some View {
        #if os(iOS)
        return self.navigationBarTitleDisplayMode(.inline)
        #else
        return self
        #endif
    }
}
