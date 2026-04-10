import Foundation
import MultipeerConnectivity

final class MultipeerTransport: NSObject, TransportProtocol {
    var onMessageReceived: ((Message) -> Void)?
    
    private let identityService: IdentityService
    private var peerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var invitedPeerIDs = Set<String>()
    
    private let sessionServiceType = "i2i-msg"
    
    init(identityService: IdentityService) {
        self.identityService = identityService
        // Use device UUID as MCPeerID displayName for reliable peer matching
        let deviceId = identityService.current?.deviceId.uuidString ?? UUID().uuidString
        print("[MultipeerTransport] Initializing with device UUID: \(deviceId)")
        self.peerID = MCPeerID(displayName: deviceId)
        super.init()
    }
    
    func start() async throws {
        if let currentDeviceId = identityService.current?.deviceId.uuidString,
           currentDeviceId != peerID.displayName {
            peerID = MCPeerID(displayName: currentDeviceId)
        }

        print("[MultipeerTransport] Starting MultipeerConnectivity with device UUID: \(peerID.displayName)")
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
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
        advertiser = nil
        browser = nil
        session = nil
        invitedPeerIDs.removeAll()
    }
    
    func getConnectedPeerIds() -> [String] {
        return session?.connectedPeers.map { $0.displayName } ?? []
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
        
        let targetDeviceId = peer.id.uuidString
        let connectedPeerIds = session.connectedPeers.map { $0.displayName }.joined(separator: ", ")
        print("[MultipeerTransport] Looking for peer ID: \(targetDeviceId). Connected peers: \(connectedPeerIds)")
        
        // Try exact match first
        if let mcPeer = session.connectedPeers.first(where: { $0.displayName == targetDeviceId }) {
            try session.send(data, toPeers: [mcPeer], with: .reliable)
            print("[MultipeerTransport] Message sent to \(peer.displayName) (ID: \(targetDeviceId))")
            return
        }
        
        // Fallback: if only one peer is connected, send to it
        // This handles cases where device IDs don't match but there's only one option
        if session.connectedPeers.count == 1, let onlyPeer = session.connectedPeers.first {
            print("[MultipeerTransport] WARNING: Device ID mismatch but sending to only connected peer \(onlyPeer.displayName)")
            try session.send(data, toPeers: [onlyPeer], with: .reliable)
            print("[MultipeerTransport] Message sent (ID mismatch override)")
            return
        }
        
        print("[MultipeerTransport] ERROR: Peer \(peer.displayName) (ID: \(targetDeviceId)) not found in connected peers. Available: \(connectedPeerIds)")
        throw TransportError.peerNotConnected
    }
    
    enum TransportError: Error {
        case notStarted
        case encodingFailed
        case peerNotConnected
    }
}

extension MultipeerTransport: MCSessionDelegate {
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        // No resources used in this implementation
    }
    
    func session(
        _ session: MCSession,
        peer peerID: MCPeerID,
        didChange state: MCSessionState
    ) {
        let stateStr = state == .connected ? "CONNECTED" : state == .connecting ? "CONNECTING" : "DISCONNECTED"
        print("[MultipeerTransport] Peer \(peerID.displayName) state: \(stateStr)")

        if state == .notConnected {
            DispatchQueue.main.async { [weak self] in
                self?.invitedPeerIDs.remove(peerID.displayName)
            }
        }
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
        print("[MultipeerTransport] Received invitation from peer: \(peerID.displayName)")
        guard let session = session else {
            print("[MultipeerTransport] ERROR: No session when receiving invitation")
            invitationHandler(false, nil)
            return
        }
        print("[MultipeerTransport] Accepting invitation from \(peerID.displayName)")
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
        print("[MultipeerTransport] Found peer: \(peerID.displayName)")
        guard let session = session else {
            print("[MultipeerTransport] ERROR: Session not ready when discovering peer")
            return
        }

        guard peerID.displayName != self.peerID.displayName else {
            print("[MultipeerTransport] Ignoring self peer: \(peerID.displayName)")
            return
        }

        guard !session.connectedPeers.contains(where: { $0.displayName == peerID.displayName }) else {
            print("[MultipeerTransport] Peer already connected, skipping invite: \(peerID.displayName)")
            return
        }

        guard !invitedPeerIDs.contains(peerID.displayName) else {
            print("[MultipeerTransport] Invitation already in progress, skipping: \(peerID.displayName)")
            return
        }

        // Break simultaneous invite loops deterministically: only one side initiates.
        guard self.peerID.displayName < peerID.displayName else {
            print("[MultipeerTransport] Waiting for peer to invite us: \(peerID.displayName)")
            return
        }
        
        // Dispatch invitation on main thread to ensure session is ready
        invitedPeerIDs.insert(peerID.displayName)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard !(self.session?.connectedPeers.contains(where: { $0.displayName == peerID.displayName }) ?? false) else {
                self.invitedPeerIDs.remove(peerID.displayName)
                print("[MultipeerTransport] Peer connected before invite, skipping: \(peerID.displayName)")
                return
            }

            print("[MultipeerTransport] Inviting peer: \(peerID.displayName)")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 60)
        }
    }
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        lostPeer peerID: MCPeerID
    ) {
        print("Lost peer: \(peerID.displayName)")
        invitedPeerIDs.remove(peerID.displayName)
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
