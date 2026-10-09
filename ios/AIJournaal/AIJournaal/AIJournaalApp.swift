import SwiftUI

@main
struct AIJournaalApp: App {
    @StateObject private var store = EpisodeStore()
    @StateObject private var player = SpeechPlayer()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(player)
                .preferredColorScheme(.dark)
                .tint(Theme.amber)
        }
    }
}
