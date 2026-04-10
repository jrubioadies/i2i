import Foundation

protocol MessageRepository: AnyObject {
    func loadConversation(localPeerId: UUID, remotePeerId: UUID) -> [Message]
    func save(_ message: Message) throws
}
