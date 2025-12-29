import SwiftUI

@main
struct ThresholdApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
                .preferredColorScheme(.dark)
        }
    }
}
