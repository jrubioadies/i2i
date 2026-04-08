import Foundation

final class PairingService {
    private let identityService: IdentityService
    private let peerRepository: any PeerRepository

    init(identityService: IdentityService, peerRepository: any PeerRepository) {
        self.identityService = identityService
        self.peerRepository = peerRepository
    }

    /// Builds a pairing payload from the local identity.
    func generatePayload() throws -> PairingPayload {
        guard let identity = identityService.current else {
            throw PairingError.identityNotLoaded
        }
        return PairingPayload(
            deviceId: identity.deviceId,
            displayName: identity.displayName,
            publicKey: identity.publicKey
        )
    }

    /// Accepts an incoming payload, validates it, and persists the peer.
    func accept(_ payload: PairingPayload) throws {
        guard payload.deviceId != identityService.current?.deviceId else {
            throw PairingError.selfPairing
        }
        let peer = Peer(
            id: payload.deviceId,
            displayName: payload.displayName,
            publicKey: payload.publicKey,
            pairingDate: Date(),
            trustStatus: .trusted
        )
        try peerRepository.save(peer)
    }

    enum PairingError: Error, LocalizedError {
        case identityNotLoaded
        case selfPairing

        var errorDescription: String? {
            switch self {
            case .identityNotLoaded: return "Identity not ready. Try again in a moment."
            case .selfPairing: return "You can't pair with yourself."
            }
        }
    }
}
