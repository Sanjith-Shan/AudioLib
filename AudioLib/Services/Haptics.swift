import Foundation
#if os(iOS)
import UIKit
#endif

enum Haptics {
    static func success() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func warning() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    static func error() {
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    static func tap(_ style: TapStyle = .light) {
        #if os(iOS)
        let feedback: UIImpactFeedbackGenerator.FeedbackStyle = {
            switch style {
            case .light:  return .light
            case .medium: return .medium
            case .heavy:  return .heavy
            }
        }()
        UIImpactFeedbackGenerator(style: feedback).impactOccurred()
        #endif
    }

    enum TapStyle { case light, medium, heavy }
}
