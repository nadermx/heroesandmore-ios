import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView(selectedTab: $selectedTab)
            } else {
                AuthView()
            }
        }
        .onAppear {
            authManager.checkStoredCredentials()
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            MarketplaceView()
                .tabItem {
                    Label("Marketplace", systemImage: "storefront")
                }
                .tag(0)

            CollectionsView()
                .tabItem {
                    Label("Collections", systemImage: "square.grid.2x2")
                }
                .tag(1)

            PriceGuideView()
                .tabItem {
                    Label("Prices", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            ScannerView()
                .tabItem {
                    Label("Scanner", systemImage: "camera.viewfinder")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(NetworkMonitor())
}
