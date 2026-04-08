import Foundation

protocol TransportProtocol {
    var onMessageReceived: ((Message) -> Void)? { get set }
    func start() async throws
    func stop()
    func send(_ message: Message, to peer: Peer) async throws
}
