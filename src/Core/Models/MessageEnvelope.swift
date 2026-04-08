import Foundation

struct MessageEnvelope {
    let messageId: UUID
    let senderPeerId: String
    let receiverPeerId: String
    let body: String
    let timestamp: Date
}
