import SwiftUI
import SwiftData

@main
struct ForgeApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: Project.self)
    }
}
