import Foundation
import Combine

@MainActor
final class MessagingViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var draft: String = ""
    @Published var peers: [Peer] = []
    @Published var selectedPeer: Peer?
    
    var localDeviceId: UUID {
        identityService?.current?.deviceId ?? UUID()
    }

    private weak var identityService: IdentityService?
    private weak var peerRepository: (any PeerRepository)?
    private weak var transport: (any TransportProtocol)?

    init() {}

    func initialize(with env: AppEnvironment) {
        self.identityService = env.identityService
        self.peerRepository = env.peerRepository
        self.transport = env.transport
        
        // Set up message receiving
        env.transport.onMessageReceived = { [weak self] message in
            self?.messages.append(message)
        }
        
        loadPeers()
    }
    
    func loadPeers() {
        guard let repository = peerRepository else { return }
        peers = repository.loadAll()
        if selectedPeer == nil && !peers.isEmpty {
            selectedPeer = peers.first
        }
    }
    
    func selectPeer(_ peer: Peer) {
        selectedPeer = peer
        messages = []
    }

    func sendTapped() {
        guard !draft.isEmpty, let peer = selectedPeer else { return }
        
        let message = Message(
            id: UUID(),
            senderPeerId: localDeviceId,
            receiverPeerId: peer.id,
            timestamp: Date(),
            body: draft,
            status: .pending
        )
        
        Task {
            do {
                try await transport?.send(message, to: peer)
                messages.append(message)
                draft = ""
            } catch {
                print("Failed to send message: \(error)")
            }
        }
    }
}

