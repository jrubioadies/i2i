import Foundation
import MultipeerConnectivity

@MainActor
final class MultipeerTransport: NSObject, TransportProtocol {
    var onMessageReceived: ((Message) -> Void)?
    
    private let identityService: IdentityService
    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private let sessionServiceType = "i2i-msg"
    
    init(identityService: IdentityService) {
        self.identityService = identityService
        self.peerID = MCPeerID(displayName: identityService.current?.displayName ?? "i2i-user")
        super.init()
    }
    
    func start() async throws {
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session
        
        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: nil,
            serviceType: sessionServiceType
        )
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser
        
        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: sessionServiceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
    }
    
    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
    }
    
    func send(_ message: Message, to peer: Peer) async throws {
        guard let session = session else {
            throw TransportError.notStarted
        }
        
        let payload = MessagePayload(
            id: message.id,
            senderPeerId: message.senderPeerId,
            receiverPeerId: message.receiverPeerId,
            timestamp: message.timestamp,
            body: message.body
        )
        
        let data = try JSONEncoder().encode(payload)
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
    
    enum TransportError: Error {
        case notStarted
        case encodingFailed
    }
}

extension MultipeerTransport: MCSessionDelegate {
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        // Handle peer connection state changes
    }
    
    func session(
        _ session: MCSession,
        didReceive data: Data,
        fromPeer peerID: MCPeerID
    ) {
        do {
            let payload = try JSONDecoder().decode(MessagePayload.self, from: data)
            let message = Message(
                id: payload.id,
                senderPeerId: payload.senderPeerId,
                receiverPeerId: payload.receiverPeerId,
                timestamp: payload.timestamp,
                body: payload.body,
                status: .received
            )
            onMessageReceived?(message)
        } catch {
            print("Failed to decode message: \(error)")
        }
    }
    
    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {
        // Streams not used in this implementation
    }
    
    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {
        // Resources not used in this implementation
    }
    
    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?
    ) {
        // Resources not used in this implementation
    }
}

extension MultipeerTransport: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        guard let session = session else {
            invitationHandler(false, nil)
            return
        }
        invitationHandler(true, session)
    }
    
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        print("Advertiser error: \(error)")
    }
}

extension MultipeerTransport: MCNearbyServiceBrowserDelegate {
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String : String]?
    ) {
        guard let session = session else { return }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        // Handle peer loss
    }
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        didNotStartBrowsingForPeers error: Error
    ) {
        print("Browser error: \(error)")
    }
}

// MARK: - Helper types

struct MessagePayload: Codable {
    let id: UUID
    let senderPeerId: UUID
    let receiverPeerId: UUID
    let timestamp: Date
    let body: String
}
