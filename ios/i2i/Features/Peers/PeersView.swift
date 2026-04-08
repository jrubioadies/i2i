import SwiftUI

struct PeersView: View {
    @StateObject private var viewModel = PeersViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.peers.isEmpty {
                    ContentUnavailableView(
                        "No Paired Devices",
                        systemImage: "person.2.slash",
                        description: Text("Pair a device from the Pair tab.")
                    )
                } else {
                    List(viewModel.peers) { peer in
                        VStack(alignment: .leading) {
                            Text(peer.displayName).font(.headline)
                            Text(peer.id.uuidString.prefix(8)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Trusted Peers")
        }
    }
}
