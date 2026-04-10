import Foundation
import Combine

@MainActor
final class MessagingViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var draft: String = ""
    @Published var peers: [Peer] = []
    @Published var selectedPeer: Peer?
    @Published var connectedPeerIds: [String] = []
    @Published var deviceName: String = ""
    @Published var pendingDisplayName: String = ""
    
    var localDeviceId: UUID {
        identityService?.current?.deviceId ?? UUID()
    }

    var isSelectedPeerConnected: Bool {
        guard let selectedPeer else { return false }
        return connectedPeerIds.contains(selectedPeer.id.uuidString)
    }

    private weak var identityService: IdentityService?
    private weak var peerRepository: (any PeerRepository)?
    private weak var messageRepository: (any MessageRepository)?
    private weak var transport: (any TransportProtocol)?
    private weak var appEnvironment: AppEnvironment?
    private var updateTimer: Timer?
    private var isInitialized = false

    init() {}

    func initialize(with env: AppEnvironment) {
        guard !isInitialized else {
            loadPeers()
            loadMessagesForSelectedPeer()
            updateConnectedPeers()
            return
        }
        isInitialized = true

        self.identityService = env.identityService
        self.peerRepository = env.peerRepository
        self.messageRepository = env.messageRepository
        self.transport = env.transport
        self.appEnvironment = env
        
        // Load device name
        if let name = env.identityService.current?.displayName {
            deviceName = name
            pendingDisplayName = name
        }
        
        // Set up message receiving
        env.transport.onMessageReceived = { [weak self] message in
            self?.handleReceivedMessage(message)
        }

        Task {
            await env.startTransportIfNeeded()
            updateConnectedPeers()
        }
        
        loadPeers()
        loadMessagesForSelectedPeer()
        
        // Periodically update connected peer IDs
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateConnectedPeers()
            }
        }
        updateConnectedPeers()
    }
    
    func loadPeers() {
        guard let repository = peerRepository else { return }
        peers = repository.loadAll()
        if selectedPeer == nil && !peers.isEmpty {
            selectedPeer = peers.first
        }
    }

    func loadMessagesForSelectedPeer() {
        guard
            let repository = messageRepository,
            let peer = selectedPeer
        else {
            messages = []
            return
        }

        messages = repository.loadConversation(localPeerId: localDeviceId, remotePeerId: peer.id)
    }
    
    private func updateConnectedPeers() {
        connectedPeerIds = transport?.getConnectedPeerIds() ?? []
    }
    
    func selectPeer(_ peer: Peer) {
        selectedPeer = peer
        loadMessagesForSelectedPeer()
    }
    
    func disconnect() {
        appEnvironment?.stopTransport()
        connectedPeerIds = []
        print("Disconnected from chat")
    }

    func reconnect() {
        guard let appEnvironment else { return }
        Task {
            await appEnvironment.startTransportIfNeeded()
            updateConnectedPeers()
        }
    }

    func saveDeviceName() {
        do {
            try identityService?.updateDisplayName(pendingDisplayName)
            deviceName = pendingDisplayName
        } catch {
            print("Failed to save device name: \(error)")
        }
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
                var sentMessage = message
                sentMessage.status = .sent
                try messageRepository?.save(sentMessage)
                messages.append(sentMessage)
                draft = ""
            } catch {
                print("Failed to send message: \(error)")
            }
        }
    }

    private func handleReceivedMessage(_ message: Message) {
        do {
            try messageRepository?.save(message)
        } catch {
            print("Failed to persist received message: \(error)")
        }

        guard let peer = selectedPeer else { return }
        let belongsToCurrentConversation =
            (message.senderPeerId == peer.id && message.receiverPeerId == localDeviceId) ||
            (message.senderPeerId == localDeviceId && message.receiverPeerId == peer.id)

        if belongsToCurrentConversation {
            messages.append(message)
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}
