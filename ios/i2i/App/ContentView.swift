import SwiftUI

struct ContentView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        TabView(selection: $env.selectedTab) {
            IdentityView()
                .tabItem { Label("Identity", systemImage: "person.crop.circle") }
                .tag(AppTab.identity)
            PairingView()
                .tabItem { Label("Pair", systemImage: "qrcode") }
                .tag(AppTab.pairing)
            PeersView()
                .tabItem { Label("Peers", systemImage: "person.2") }
                .tag(AppTab.peers)
            MessagingView()
                .tabItem { Label("Messages", systemImage: "message") }
                .tag(AppTab.messages)
        }
    }
}
