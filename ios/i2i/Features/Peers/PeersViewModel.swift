import Foundation
import Combine

@MainActor
final class PeersViewModel: ObservableObject {
    @Published var peers: [Peer] = []

    // TODO: Ticket 4 – inject PeerRepository and load on appear
}
