import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            IdentityView()
                .tabItem { Label("Identity", systemImage: "person.crop.circle") }
            PairingView()
                .tabItem { Label("Pair", systemImage: "qrcode") }
            PeersView()
                .tabItem { Label("Peers", systemImage: "person.2") }
            MessagingView()
                .tabItem { Label("Messages", systemImage: "message") }
        }
    }
}
