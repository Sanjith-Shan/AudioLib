import Foundation
import Observation

@Observable
class AppRouter {
    static let shared = AppRouter()

    var selectedTab: Int = 1  // 1 = Library (center/default)
    var showingPlayer: Bool = false
    var currentBookID: UUID? = nil

    private init() {}
}
