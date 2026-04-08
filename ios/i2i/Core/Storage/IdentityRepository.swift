import Foundation

protocol IdentityRepository {
    func load() -> LocalIdentity?
    func save(_ identity: LocalIdentity) throws
    func delete() throws
}
