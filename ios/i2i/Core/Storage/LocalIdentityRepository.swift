import Foundation

final class LocalIdentityRepository: IdentityRepository {
    private let key = "com.i2i.identity"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> LocalIdentity? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(LocalIdentity.self, from: data)
    }

    func save(_ identity: LocalIdentity) throws {
        let data = try JSONEncoder().encode(identity)
        defaults.set(data, forKey: key)
    }
}
