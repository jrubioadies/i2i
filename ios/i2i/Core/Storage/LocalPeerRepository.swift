import Foundation

final class LocalPeerRepository: PeerRepository {
    private let fileURL: URL

    init() {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        fileURL = support.appendingPathComponent("peers.json")
    }

    func loadAll() -> [Peer] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Peer].self, from: data)) ?? []
    }

    func save(_ peer: Peer) throws {
        var peers = loadAll()
        if let index = peers.firstIndex(where: { $0.id == peer.id }) {
            peers[index] = peer
        } else {
            peers.append(peer)
        }
        try write(peers)
    }

    func remove(id: UUID) throws {
        var peers = loadAll()
        peers.removeAll { $0.id == id }
        try write(peers)
    }

    // MARK: - Private

    private func write(_ peers: [Peer]) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(peers)
        try data.write(to: fileURL, options: .atomic)
    }
}
