import Foundation
import Security

enum KeyStore {
    static let privateKeyTag = "com.i2i.identity.privateKey"

    static func save(data: Data, tag: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeyStoreError.saveFailed(status) }
    }

    static func load(tag: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeyStoreError.loadFailed(status)
        }
        return data
    }

    enum KeyStoreError: Error {
        case saveFailed(OSStatus)
        case loadFailed(OSStatus)
    }
}
