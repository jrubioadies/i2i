import Foundation
import Security
import CryptoKit

enum KeyStore {
    static let privateKeyTag = "com.i2i.identity.privateKey"

    // MARK: - CryptoKit helpers

    static func savePrivateKey(_ key: Curve25519.Signing.PrivateKey, tag: String) throws {
        try save(data: key.rawRepresentation, tag: tag)
    }

    static func loadPrivateKey(tag: String) throws -> Curve25519.Signing.PrivateKey {
        let data = try load(tag: tag)
        return try Curve25519.Signing.PrivateKey(rawRepresentation: data)
    }

    static func exists(tag: String) -> Bool {
        (try? load(tag: tag)) != nil
    }

    // MARK: - Raw data

    static func save(data: Data, tag: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            // Only accessible when device is unlocked; not included in backups;
            // not transferable to other devices.
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false,
            kSecValueData as String: data
        ]
        SecItemDelete(baseQuery(tag: tag) as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeyStoreError.saveFailed(status) }
    }

    static func load(tag: String) throws -> Data {
        let query: [String: Any] = baseQuery(tag: tag).merging([
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]) { _, new in new }
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeyStoreError.loadFailed(status)
        }
        return data
    }

    // MARK: - Private

    private static func baseQuery(tag: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag
        ]
    }

    // MARK: - Errors

    enum KeyStoreError: Error, LocalizedError {
        case saveFailed(OSStatus)
        case loadFailed(OSStatus)

        var errorDescription: String? {
            switch self {
            case .saveFailed(let s): return "Keychain save failed (OSStatus \(s))"
            case .loadFailed(let s): return "Keychain load failed (OSStatus \(s))"
            }
        }
    }
}
