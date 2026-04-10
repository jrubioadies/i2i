import SwiftUI

struct MessagingView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel = MessagingViewModel()
    @State private var showNameEditor = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.peers.isEmpty {
                    EmptyStateView(
                        title: "No Paired Devices",
                        systemImage: "person.2.slash",
                        description: "Pair a device from the Pair tab to start messaging."
                    )
                } else {
                    // Header with peer selection and status
                    VStack(spacing: 8) {
                        HStack {
                            Picker("Select Peer", selection: $viewModel.selectedPeer) {
                                ForEach(viewModel.peers) { peer in
                                    Text(peer.displayName).tag(peer as Peer?)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Button(action: { showNameEditor = true }) {
                                Image(systemName: "pencil.circle")
                                    .font(.title3)
                            }
                            .help("Edit device name")
                        }
                        .padding()
                        
                        if viewModel.isSelectedPeerConnected {
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Spacer()
                                Text(viewModel.deviceName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        } else {
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundStyle(.gray)
                                    .font(.caption)
                                Text("Disconnected")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text(viewModel.deviceName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                    .background(Color(.systemGray6))
                    
                    // Messages
                    ScrollViewReader { proxy in
                        VStack {
                            ScrollView {
                                VStack(spacing: 12) {
                                    if viewModel.messages.isEmpty {
                                        VStack {
                                            Spacer()
                                            Text("No messages yet")
                                                .foregroundStyle(.secondary)
                                                .font(.callout)
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    } else {
                                        ForEach(viewModel.messages) { message in
                                            messageBubble(for: message)
                                                .id(message.id)
                                        }
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                            }
                            .onChange(of: viewModel.messages.count, perform: { _ in
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            })
                        }
                    }
                    
                    Divider()
                    
                    // Input
                    HStack(spacing: 12) {
                        TextField("Message", text: $viewModel.draft)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3)
                        
                        Button(action: { viewModel.sendTapped() }) {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.draft.isEmpty || !viewModel.isSelectedPeerConnected)
                    }
                    .padding()
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        env.selectedTab = .peers
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isSelectedPeerConnected {
                        Button(action: { viewModel.disconnect() }) {
                            Image(systemName: "power.circle")
                                .foregroundStyle(.red)
                        }
                        .help("Disconnect")
                    } else {
                        Button(action: { viewModel.reconnect() }) {
                            Image(systemName: "arrow.clockwise.circle")
                        }
                        .help("Reconnect")
                    }
                }
            }
            .sheet(isPresented: $showNameEditor) {
                editNameSheet
            }
            .onAppear {
                viewModel.initialize(with: env)
            }
            .onChange(of: viewModel.selectedPeer?.id, perform: { _ in
                viewModel.loadMessagesForSelectedPeer()
            })
        }
    }
    
    @ViewBuilder
    private func messageBubble(for message: Message) -> some View {
        HStack {
            if message.senderPeerId == viewModel.localDeviceId {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.body)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.body)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                }
                Spacer()
            }
        }
    }
    
    private var editNameSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Name")
                        .font(.headline)
                    
                    TextField("Device Name", text: $viewModel.pendingDisplayName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.vertical, 8)
                    
                    Text("This name will be shown to other devices when pairing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                Spacer()
                
                Button("Save") {
                    viewModel.saveDeviceName()
                    showNameEditor = false
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .navigationTitle("Edit Device Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showNameEditor = false }
                }
            }
        }
    }
}
