import SwiftUI

struct PairingView: View {
    @StateObject private var viewModel = PairingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .foregroundStyle(.secondary)
                Text("QR pairing – coming in Ticket 6")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                Spacer()
                Button("Show My Pairing QR") { viewModel.showQRTapped() }
                    .buttonStyle(.borderedProminent)
                Button("Scan Peer QR") { viewModel.scanTapped() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Pair Device")
        }
    }
}
