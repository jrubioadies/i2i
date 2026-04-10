import SwiftUI

@main
struct i2iApp: App {
    @StateObject private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(env)
        }
    }
}
