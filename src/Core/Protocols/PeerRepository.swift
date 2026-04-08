import Foundation

protocol PeerRepository {
    func listPeers() throws -> [PeerRecord]
    func addPeer(_ peer: PeerRecord) throws
    func removePeer(id: String) throws
}
