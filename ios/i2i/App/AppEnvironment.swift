import Foundation

/// Shared service container. Injected as @EnvironmentObject from i2iApp.
@MainActor
final class AppEnvironment: ObservableObject {
    let identityService: IdentityService
    let pairingService: PairingService
    let peerRepository: any PeerRepository
    
    @Published var peerChangeCount = 0

    init() {
        let identity = IdentityService()
        let peers = LocalPeerRepository()
        self.identityService = identity
        self.peerRepository = peers
        self.pairingService = PairingService(identityService: identity, peerRepository: peers)
    }

    func bootstrap() {
        try? identityService.loadOrCreate()
    }
    
    func notifyPeerChanged() {
        peerChangeCount += 1
    }
}
