import Foundation

struct Peer: Identifiable, Codable {
    let id: UUID
    var displayName: String
    let publicKey: Data
    let pairingDate: Date
    var trustStatus: TrustStatus

    enum TrustStatus: String, Codable {
        case trusted
        case revoked
    }
}
