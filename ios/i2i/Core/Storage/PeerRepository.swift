import Foundation

protocol PeerRepository: AnyObject {
    func loadAll() -> [Peer]
    func save(_ peer: Peer) throws
    func remove(id: UUID) throws
}
