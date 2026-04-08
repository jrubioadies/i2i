import Foundation

protocol PairingCoordinating {
    func makePairingPayload(from identity: DeviceIdentity) throws -> PairingPayload
    func pair(with payload: PairingPayload) throws -> PeerRecord
}
