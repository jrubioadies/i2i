import Foundation

/// Minimum data exchanged during a pairing handshake.
/// Serialised to JSON and encoded in a QR code.
struct PairingPayload: Codable {
    let deviceId: UUID
    let displayName: String
    let publicKey: Data

    // MARK: - Serialisation

    func encoded() throws -> String {
        let data = try JSONEncoder().encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw PairingPayloadError.encodingFailed
        }
        return string
    }

    static func decode(from string: String) throws -> PairingPayload {
        guard let data = string.data(using: .utf8) else {
            throw PairingPayloadError.invalidString
        }
        return try JSONDecoder().decode(PairingPayload.self, from: data)
    }

    enum PairingPayloadError: Error, LocalizedError {
        case encodingFailed
        case invalidString

        var errorDescription: String? {
            switch self {
            case .encodingFailed: return "Failed to encode pairing payload."
            case .invalidString: return "QR content is not a valid pairing payload."
            }
        }
    }
}
