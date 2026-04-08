import Foundation

/// Shared service container. Injected as @EnvironmentObject from i2iApp.
@MainActor
final class AppEnvironment: ObservableObject {
    let identityService: IdentityService
    let pairingService: PairingService
    let peerRepository: any PeerRepository
    let transport: MultipeerTransport
    
    @Published var peerChangeCount = 0

    init() {
        let identity = IdentityService()
        let peers = LocalPeerRepository()
        self.identityService = identity
        self.peerRepository = peers
        self.pairingService = PairingService(identityService: identity, peerRepository: peers)
        self.transport = MultipeerTransport(identityService: identity)
    }

    func bootstrap() {
        try? identityService.loadOrCreate()
        Task {
            try? await transport.start()
        }
    }
    
    func notifyPeerChanged() {
        peerChangeCount += 1
    }
}
