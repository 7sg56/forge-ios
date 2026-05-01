import SwiftUI
import SwiftData

@main
struct ForgeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Project.self, SkillTrack.self])
    }
}
