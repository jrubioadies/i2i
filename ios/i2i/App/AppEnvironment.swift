import Foundation

enum AppTab: Hashable {
    case identity
    case pairing
    case peers
    case messages
}

/// Shared service container. Injected as @EnvironmentObject from i2iApp.
@MainActor
final class AppEnvironment: ObservableObject {
    let identityService: IdentityService
    let pairingService: PairingService
    let peerRepository: any PeerRepository
    let messageRepository: any MessageRepository
    let transport: MultipeerTransport
    
    @Published var peerChangeCount = 0
    @Published var selectedTab: AppTab = .identity
    @Published private(set) var didBootstrap = false
    @Published private(set) var bootstrapError: String?
    private var hasBootstrapped = false
    private var hasStartedTransport = false

    init() {
        let identity = IdentityService()
        let peers = LocalPeerRepository()
        let messages = LocalMessageRepository()
        self.identityService = identity
        self.peerRepository = peers
        self.messageRepository = messages
        self.pairingService = PairingService(identityService: identity, peerRepository: peers)
        self.transport = MultipeerTransport(identityService: identity)
    }

    func bootstrap() {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true

        do {
            try identityService.loadOrCreate()
            bootstrapError = nil
        } catch {
            bootstrapError = error.localizedDescription
            print("Failed to load or create identity: \(error)")
        }

        didBootstrap = true
    }

    func startTransportIfNeeded() async {
        guard !hasStartedTransport else { return }
        hasStartedTransport = true

        do {
            try await transport.start()
        } catch {
            hasStartedTransport = false
            print("Failed to start transport: \(error)")
        }
    }

    func stopTransport() {
        transport.stop()
        hasStartedTransport = false
    }
    
    func notifyPeerChanged() {
        peerChangeCount += 1
    }
}
