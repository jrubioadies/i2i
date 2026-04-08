import Foundation

@MainActor
final class PairingViewModel: ObservableObject {
    @Published var payloadString: String?
    @Published var errorMessage: String?

    func generatePayload(using service: PairingService) {
        do {
            let payload = try service.generatePayload()
            payloadString = try payload.encoded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptPayload(string: String, using service: PairingService) {
        do {
            let payload = try PairingPayload.decode(from: string)
            try service.accept(payload)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scanTapped() {
        // TODO: Ticket 6 – open camera scanner
    }
}
