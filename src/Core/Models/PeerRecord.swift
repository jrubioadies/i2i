import Foundation

struct PeerRecord {
    let peerId: String
    let peerDisplayName: String
    let publicIdentityData: Data
    let pairingDate: Date
    let trustStatus: TrustStatus
}

enum TrustStatus {
    case trusted
    case revoked
}
