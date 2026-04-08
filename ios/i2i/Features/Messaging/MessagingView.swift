import SwiftUI

struct MessagingView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel = MessagingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.peers.isEmpty {
                    ContentUnavailableView(
                        "No Paired Devices",
                        systemImage: "person.2.slash",
                        description: Text("Pair a device from the Pair tab to start messaging.")
                    )
                } else {
                    Picker("Select Peer", selection: $viewModel.selectedPeer) {
                        ForEach(viewModel.peers) { peer in
                            Text(peer.displayName).tag(peer as Peer?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    List(viewModel.messages) { message in
                        HStack {
                            if message.senderPeerId == viewModel.localDeviceId {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(message.body)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(message.body)
                                        .padding(8)
                                        .background(Color.secondary.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Message", text: $viewModel.draft)
                            .textFieldStyle(.roundedBorder)
                        Button("Send") { viewModel.sendTapped() }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.draft.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Messages")
            .onAppear {
                viewModel.initialize(with: env)
            }
        }
    }
}

