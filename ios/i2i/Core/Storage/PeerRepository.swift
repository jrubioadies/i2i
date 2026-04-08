import Foundation

protocol PeerRepository {
    func loadAll() -> [Peer]
    func save(_ peer: Peer) throws
    func remove(id: UUID) throws
}
