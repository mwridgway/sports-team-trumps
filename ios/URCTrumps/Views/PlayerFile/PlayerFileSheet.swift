import SwiftUI

/// The player file: hero header, a glass tab switcher, and Season / Career / Profile content.
struct PlayerFileSheet: View {
    @Environment(\.dismiss) private var dismiss

    let player: Player
    let library: Library
    @State private var tab: PlayerFileTab

    init(player: Player, library: Library, tab: PlayerFileTab = .season) {
        self.player = player
        self.library = library
        _tab = State(initialValue: tab)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                PlayerFileHeader(player: player, leads: library.leads(player))
                Group {
                    switch tab {
                    case .season: SeasonTab(player: player)
                    case .career: CareerTab(player: player)
                    case .profile: ProfileTab(player: player)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.pitch.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button("Done") { dismiss() }
                .buttonStyle(.glass)
                .controlSize(.large)
                .padding(.trailing, 14)
                .padding(.top, 14)
        }
        .safeAreaInset(edge: .bottom) { switcher }
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.pitch)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    @ViewBuilder
    private func tabButton(_ option: PlayerFileTab, selected: Bool) -> some View {
        let button = Button { withAnimation(.snappy) { tab = option } } label: {
            Text(option.rawValue)
                .font(.subheadline.weight(selected ? .bold : .semibold))
                .padding(.horizontal, 8)
                .frame(minHeight: 44)
        }
        if selected {
            button.buttonStyle(.glassProminent).tint(.amber).foregroundStyle(Color.amberInk)
        } else {
            button.buttonStyle(.glass).foregroundStyle(.white)
        }
    }

    private var switcher: some View {
        GlassEffectContainer(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(PlayerFileTab.allCases) { option in
                    let selected = option == tab
                    tabButton(option, selected: selected)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
        .padding(.bottom, 6)
    }
}
