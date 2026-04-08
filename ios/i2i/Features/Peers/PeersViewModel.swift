import Foundation

@MainActor
final class PeersViewModel: ObservableObject {
    @Published var peers: [Peer] = []

    private var repository: (any PeerRepository)?

    init() {
    }

    func initialize(with env: AppEnvironment) {
        self.repository = env.peerRepository
        reload()
    }

    func onAppear() {
        reload()
    }

    func reload() {
        guard let repository = repository else { return }
        peers = repository.loadAll()
    }

    func remove(id: UUID) {
        guard let repository = repository else { return }
        try? repository.remove(id: id)
        peers.removeAll { $0.id == id }
    }
}
