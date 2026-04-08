import Foundation

struct Message: Identifiable {
    let id: UUID
    let senderPeerId: UUID
    let receiverPeerId: UUID
    let timestamp: Date
    let body: String
    var status: Status

    enum Status {
        case pending
        case sent
        case received
    }
}
