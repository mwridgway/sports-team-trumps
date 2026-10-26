import SwiftUI

/// Searchable list of every player; leaders first, tap for the player file.
struct BrowseView: View {
    let library: Library
    @State private var query = ""
    @State private var club: String?
    @State private var selected: Player?

    init(library: Library, initialFile: Player? = nil) {
        self.library = library
        _selected = State(initialValue: initialFile)
    }

    private var players: [Player] {
        library.browseOrder
            .filter { club == nil || $0.club == club }
            .filter { query.isEmpty || $0.fullName.localizedStandardContains(query) || $0.club.localizedStandardContains(query) }
    }

    var body: some View {
        List(players) { player in
            Button { selected = player } label: { PlayerListRow(player: player, leads: library.leads(player)) }
                .listRowBackground(Color.pitchLight)
                .listRowSeparatorTint(Color.pitchLine)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.pitch.ignoresSafeArea())
        .overlay {
            if players.isEmpty { ContentUnavailableView.search }
        }
        .navigationTitle("Players")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Name or club")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Club", selection: $club) {
                        Text("All clubs").tag(String?.none)
                        ForEach(library.clubs, id: \.self) { Text($0).tag(String?.some($0)) }
                    }
                } label: {
                    Label(club ?? "All clubs", systemImage: "line.3.horizontal.decrease")
                }
            }
        }
        .sheet(item: $selected) { PlayerFileSheet(player: $0, library: library) }
    }
}
