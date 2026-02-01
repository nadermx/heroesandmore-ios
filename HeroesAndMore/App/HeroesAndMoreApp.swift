import SwiftUI

@main
struct HeroesAndMoreApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(networkMonitor)
        }
    }
}
