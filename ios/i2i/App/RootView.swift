import SwiftUI

struct RootView: View {
    @EnvironmentObject var env: AppEnvironment

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            if env.didBootstrap {
                ContentView()
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Starting i2i...")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                .padding(24)
            }
        }
        .overlay(alignment: .bottom) {
            if let error = env.bootstrapError {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .onAppear {
            env.bootstrap()
        }
    }
}
