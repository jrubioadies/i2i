import SwiftUI

struct PairingView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel = PairingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                if let payload = viewModel.payloadString {
                    // Ticket 6 will render this as a proper QR image.
                    // For now, show the raw payload to verify generation works.
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("Payload ready")
                            .font(.headline)
                        Text(payload)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    Image(systemName: "qrcode")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(.secondary)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                Button("Show My Pairing QR") {
                    viewModel.generatePayload(using: env.pairingService)
                }
                .buttonStyle(.borderedProminent)

                Button("Scan Peer QR") { viewModel.scanTapped() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Pair Device")
        }
    }
}
