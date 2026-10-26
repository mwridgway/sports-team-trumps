import SwiftUI

/// Loads the bundled data, then hosts the navigation stack.
struct RootView: View {
    enum Route: Hashable { case game(GameModel), browse }

    @AppStorage("difficulty") private var difficulty = Difficulty.medium
    @State private var library: Library?
    @State private var loadFailed = false
    @State private var path: [Route] = []
    #if DEBUG
    @State private var debugFile: DebugScenario.File?
    #endif

    var body: some View {
        Group {
            if let library {
                stack(library)
            } else {
                loading
            }
        }
        .task {
            do {
                let data = try await GameData.loadBundled()
                library = Library(data: data)
            } catch {
                loadFailed = true
            }
        }
    }

    private var loading: some View {
        ZStack {
            Color.pitch.ignoresSafeArea()
            if loadFailed {
                ContentUnavailableView("Couldn't load the players", systemImage: "exclamationmark.triangle")
            } else {
                ProgressView().controlSize(.large)
            }
        }
    }

    private func stack(_ library: Library) -> some View {
        NavigationStack(path: $path) {
            HomeView(library: library, difficulty: $difficulty, onPlay: { startGame(library) }, onBrowse: { path.append(.browse) })
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .game(let model):
                        GameView(
                            model: model, library: library,
                            onRematch: { startGame(library, replacing: true) }, onHome: { path = [] }
                        )
                    case .browse:
                        BrowseView(library: library)
                    }
                }
        }
        .tint(.amber)
        #if DEBUG
        .task { DebugScenario.current?.apply(library: library, difficulty: difficulty, path: $path, file: $debugFile) }
        .sheet(item: $debugFile) { PlayerFileSheet(player: $0.player, library: library, tab: $0.tab) }
        #endif
    }

    private func startGame(_ library: Library, replacing: Bool = false) {
        let route = Route.game(GameModel(library: library, difficulty: difficulty))
        if replacing, !path.isEmpty { path[path.count - 1] = route } else { path.append(route) }
    }
}
