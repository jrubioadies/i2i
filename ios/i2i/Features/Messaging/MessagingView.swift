import SwiftUI

struct MessagingView: View {
    @StateObject private var viewModel = MessagingViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                List(viewModel.messages) { message in
                    HStack {
                        if message.senderPeerId == viewModel.localDeviceId {
                            Spacer()
                            Text(message.body)
                                .padding(8)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Text(message.body)
                                .padding(8)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
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
            .navigationTitle("Messages")
        }
    }
}
