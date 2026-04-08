import SwiftUI

struct PairingView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel = PairingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                qrSection

                resultBanner

                Spacer()

                actionButtons
            }
            .padding()
            .navigationTitle("Pair Device")
            .sheet(isPresented: $viewModel.isShowingScanner) {
                scannerSheet
            }
            .onAppear {
                viewModel.appEnvironment = env
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var qrSection: some View {
        if let payload = viewModel.payloadString {
            VStack(spacing: 12) {
                QRCodeView(content: payload)
                    .frame(width: 220, height: 220)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                Text("Scan this QR from the other device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var resultBanner: some View {
        switch viewModel.pairingResult {
        case .success(let name):
            Label("Paired with \(name)", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .font(.subheadline.bold())
        case .failure(let msg):
            Text(msg)
                .foregroundStyle(.red)
                .font(.footnote)
                .multilineTextAlignment(.center)
        case .none:
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Show My Pairing QR") {
                viewModel.generatePayload(using: env.pairingService)
            }
            .buttonStyle(.borderedProminent)

            Button("Scan Peer QR") {
                viewModel.scanTapped()
            }
            .buttonStyle(.bordered)
        }
    }

    private var scannerSheet: some View {
        NavigationStack {
            QRScannerView(
                onScan: { value in
                    viewModel.handleScannedString(value, using: env.pairingService)
                },
                onDismiss: {
                    viewModel.isShowingScanner = false
                }
            )
            .ignoresSafeArea()
            .navigationTitle("Scan QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.isShowingScanner = false }
                }
            }
        }
    }
}
