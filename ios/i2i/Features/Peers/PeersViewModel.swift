import Foundation

@MainActor
final class PeersViewModel: ObservableObject {
    @Published var peers: [Peer] = []

    private let repository: any PeerRepository

    init(repository: any PeerRepository = LocalPeerRepository()) {
        self.repository = repository
    }

    func onAppear() {
        peers = repository.loadAll()
    }

    func remove(id: UUID) {
        try? repository.remove(id: id)
        peers.removeAll { $0.id == id }
    }
}
