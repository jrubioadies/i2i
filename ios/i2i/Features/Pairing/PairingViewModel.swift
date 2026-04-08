import Foundation

@MainActor
final class PairingViewModel: ObservableObject {
    @Published var payloadString: String?
    @Published var isShowingScanner = false
    @Published var pairingResult: PairingResult?
    @Published var errorMessage: String?
    
    weak var appEnvironment: AppEnvironment?

    enum PairingResult {
        case success(peerName: String)
        case failure(String)
    }

    func generatePayload(using service: PairingService) {
        errorMessage = nil
        do {
            let payload = try service.generatePayload()
            payloadString = try payload.encoded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scanTapped() {
        isShowingScanner = true
    }

    func handleScannedString(_ string: String, using service: PairingService) {
        isShowingScanner = false
        do {
            let payload = try PairingPayload.decode(from: string)
            try service.accept(payload)
            appEnvironment?.notifyPeerChanged()
            pairingResult = .success(peerName: payload.displayName)
        } catch {
            pairingResult = .failure(error.localizedDescription)
        }
    }
}
