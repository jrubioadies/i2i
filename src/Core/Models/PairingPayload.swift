import Foundation

struct PairingPayload {
    let deviceId: String
    let displayName: String
    let publicKeyData: Data
    let createdAt: Date
}
