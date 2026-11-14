import SwiftUI

@main
struct VerbaApp: App {
    var body: some Scene {
        Window("Verba", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
