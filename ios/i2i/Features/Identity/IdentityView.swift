import SwiftUI

struct IdentityView: View {
    @EnvironmentObject var env: AppEnvironment
    @StateObject private var viewModel = IdentityViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Device") {
                    LabeledContent("ID", value: viewModel.deviceIdShort)
                    LabeledContent("Name", value: viewModel.displayName)
                    LabeledContent("Created", value: viewModel.createdAt)
                }
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("My Identity")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { viewModel.editTapped() }
                }
            }
            .onAppear { viewModel.load(from: env.identityService) }
        }
    }
}
