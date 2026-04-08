import Foundation

@MainActor
final class IdentityViewModel: ObservableObject {
    @Published var deviceIdShort: String = "–"
    @Published var displayName: String = "–"
    @Published var createdAt: String = "–"
    @Published var errorMessage: String?

    private let service: IdentityService

    init(service: IdentityService = IdentityService()) {
        self.service = service
    }

    func onAppear() {
        do {
            let identity = try service.loadOrCreate()
            apply(identity)
        } catch {
            errorMessage = "Failed to load identity: \(error.localizedDescription)"
        }
    }

    func editTapped() {
        // TODO: Ticket 2 extension – show edit sheet for display name
    }

    // MARK: - Private

    private func apply(_ identity: LocalIdentity) {
        deviceIdShort = String(identity.deviceId.uuidString.prefix(8)).uppercased()
        displayName = identity.displayName
        createdAt = identity.createdAt.formatted(date: .abbreviated, time: .omitted)
    }
}
