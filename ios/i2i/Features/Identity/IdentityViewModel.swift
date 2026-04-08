import Foundation

@MainActor
final class IdentityViewModel: ObservableObject {
    @Published var deviceIdShort: String = "–"
    @Published var displayName: String = "–"
    @Published var createdAt: String = "–"
    @Published var errorMessage: String?

    func load(from service: IdentityService) {
        do {
            let identity = try service.loadOrCreate()
            apply(identity)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func editTapped() {
        // TODO: show edit sheet for display name
    }

    private func apply(_ identity: LocalIdentity) {
        deviceIdShort = String(identity.deviceId.uuidString.prefix(8)).uppercased()
        displayName = identity.displayName
        createdAt = identity.createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}
