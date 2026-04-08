import Foundation
import Combine

@MainActor
final class MessagingViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var draft: String = ""

    let localDeviceId: UUID = UUID() // TODO: Ticket 2 – replace with real identity

    func sendTapped() {
        // TODO: Ticket 9 – send via transport
        draft = ""
    }
}
