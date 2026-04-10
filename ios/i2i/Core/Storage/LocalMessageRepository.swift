import Foundation

final class LocalMessageRepository: MessageRepository {
    private let fileURL: URL

    init() {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        fileURL = support.appendingPathComponent("messages.json")
    }

    func loadConversation(localPeerId: UUID, remotePeerId: UUID) -> [Message] {
        loadAll()
            .filter { message in
                (message.senderPeerId == localPeerId && message.receiverPeerId == remotePeerId) ||
                (message.senderPeerId == remotePeerId && message.receiverPeerId == localPeerId)
            }
            .sorted { $0.timestamp < $1.timestamp }
    }

    func save(_ message: Message) throws {
        var messages = loadAll()
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
        }
        try write(messages)
    }

    private func loadAll() -> [Message] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Message].self, from: data)) ?? []
    }

    private func write(_ messages: [Message]) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(messages)
        try data.write(to: fileURL, options: .atomic)
    }
}
