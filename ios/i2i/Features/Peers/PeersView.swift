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
                    List {
                        ForEach(viewModel.peers) { peer in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(peer.displayName).font(.headline)
                                Text(String(peer.id.uuidString.prefix(8)).uppercased())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Paired \(peer.pairingDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .onDelete { offsets in
                            offsets.forEach { viewModel.remove(id: viewModel.peers[$0].id) }
                        }
                    }
                }
            }
            .navigationTitle("Trusted Peers")
            .onAppear { viewModel.onAppear() }
        }
    }
}
