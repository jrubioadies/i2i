import Foundation

final class LocalIdentityRepository: IdentityRepository {
    private let fileURL: URL

    init() {
        let support = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        fileURL = support.appendingPathComponent("identity.json")
    }

    func load() -> LocalIdentity? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(LocalIdentity.self, from: data)
    }

    func save(_ identity: LocalIdentity) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(identity)
        try data.write(to: fileURL, options: .atomic)
    }

    func delete() throws {
        try FileManager.default.removeItem(at: fileURL)
    }
}
