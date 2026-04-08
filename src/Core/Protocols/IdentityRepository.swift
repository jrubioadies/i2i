import Foundation

protocol IdentityRepository {
    func loadIdentity() throws -> DeviceIdentity?
    func saveIdentity(_ identity: DeviceIdentity) throws
}
