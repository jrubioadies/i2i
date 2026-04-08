import Foundation
import CryptoKit
import UIKit

final class IdentityService {
    private let repository: IdentityRepository
    private(set) var current: LocalIdentity?

    init(repository: IdentityRepository = LocalIdentityRepository()) {
        self.repository = repository
    }

    /// Returns the existing identity or creates one on first launch.
    @discardableResult
    func loadOrCreate() throws -> LocalIdentity {
        if let existing = repository.load() {
            current = existing
            return existing
        }
        return try create()
    }

    func updateDisplayName(_ name: String) throws {
        guard var identity = current else { return }
        identity.displayName = name
        try repository.save(identity)
        current = identity
    }

    // MARK: - Private

    private func create() throws -> LocalIdentity {
        let privateKey = Curve25519.Signing.PrivateKey()
        try KeyStore.save(data: privateKey.rawRepresentation, tag: KeyStore.privateKeyTag)

        let identity = LocalIdentity(
            deviceId: UUID(),
            displayName: UIDevice.current.name,
            createdAt: Date(),
            publicKey: privateKey.publicKey.rawRepresentation
        )
        try repository.save(identity)
        current = identity
        return identity
    }
}
