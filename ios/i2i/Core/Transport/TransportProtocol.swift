import Foundation

protocol TransportProtocol: AnyObject {
    var onMessageReceived: ((Message) -> Void)? { get set }
    func start() async throws
    func stop()
    func send(_ message: Message, to peer: Peer) async throws
    func getConnectedPeerIds() -> [String]  // Returns device UUIDs of connected peers
}
