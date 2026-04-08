import Foundation
import CryptoKit
import UIKit

final class IdentityService {
    private let repository: any IdentityRepository
    private(set) var current: LocalIdentity?

    init(repository: any IdentityRepository = LocalIdentityRepository()) {
        self.repository = repository
    }

    /// Returns the existing identity or creates one on first launch.
    /// If the public data exists but the Keychain key is gone (e.g. after a
    /// backup restore), wipes the stale record and generates a fresh identity.
    @discardableResult
    func loadOrCreate() throws -> LocalIdentity {
        if let stored = repository.load() {
            guard KeyStore.exists(tag: KeyStore.privateKeyTag) else {
                // Private key is unrecoverable – generate a fresh identity.
                // Existing pairings will be invalidated; recovery flows are out of v1 scope.
                try? repository.delete()
                return try create()
            }
            current = stored
            return stored
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
        try KeyStore.savePrivateKey(privateKey, tag: KeyStore.privateKeyTag)

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
