import Foundation

protocol TransportClient {
    func send(_ message: MessageEnvelope) throws
    func startReceiving(onMessage: @escaping (MessageEnvelope) -> Void)
}
