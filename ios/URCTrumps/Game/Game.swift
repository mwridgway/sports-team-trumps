/// The rules of the game as a plain value type: piles, ruck, turn order and hand resolution.
struct Game: Sendable {
    let categories: [Category]
    let deck: [Player]
    private(set) var userPile: [Player]
    private(set) var cpuPile: [Player]
    private(set) var ruck: [Player] = []
    private(set) var picker: Side = .user
    private(set) var hands: [HandRecord] = []
    private(set) var peakRuck = 0
    private var seenIDs: Set<Int> = []
    private var endedEarly = false

    init(categories: [Category], userPile: [Player], cpuPile: [Player]) {
        self.categories = categories
        self.userPile = userPile
        self.cpuPile = cpuPile
        deck = userPile + cpuPile
    }

    init<G: RandomNumberGenerator>(library: Library, using rng: inout G) {
        let deal = Deck.deal(players: library.players, leaders: library.data.leaders, using: &rng)
        self.init(categories: library.categories, userPile: deal.user, cpuPile: deal.cpu)
    }

    var isOver: Bool { endedEarly || userPile.isEmpty || cpuPile.isEmpty }

    var result: GameResult? {
        guard isOver else { return nil }
        if userPile.count == cpuPile.count { return .draw }
        return userPile.count > cpuPile.count ? .win : .lose
    }

    var userCard: Player? { userPile.first }
    var cpuCard: Player? { cpuPile.first }

    /// Plays both top cards on `category`; the winner takes both plus any ruck.
    @discardableResult
    mutating func play(_ category: Category) -> HandRecord {
        precondition(!isOver, "game is over")
        let pickedBy = picker
        let user = userPile.removeFirst()
        let cpu = cpuPile.removeFirst()
        seenIDs.insert(user.id)
        seenIDs.insert(cpu.id)

        let mine = user.value(for: category), theirs = cpu.value(for: category)
        let outcome: Outcome = mine == theirs ? .draw : .win(mine > theirs ? .user : .cpu)
        switch outcome {
        case .draw:
            ruck += [user, cpu]
            peakRuck = max(peakRuck, ruck.count)
        case .win(.user):
            userPile += [user, cpu] + ruck
            ruck = []
            picker = .user
        case .win(.cpu):
            cpuPile += [cpu, user] + ruck
            ruck = []
            picker = .cpu
        }
        let record = HandRecord(
            number: hands.count + 1, picker: pickedBy, category: category,
            userCard: user, cpuCard: cpu, outcome: outcome, ruckAfter: ruck.count
        )
        hands.append(record)
        return record
    }

    /// Stops the game now; whoever holds more cards wins.
    mutating func endEarly() { endedEarly = true }

    /// Cards the computer cannot rule out as the user's top card: the deck minus its own pile,
    /// the ruck and everything already revealed (falling back to the revealed ones).
    var cpuCandidates: [Player] {
        let hidden = Set(cpuPile.map(\.id)).union(ruck.map(\.id))
        let possible = deck.filter { !hidden.contains($0.id) }
        let unseen = possible.filter { !seenIDs.contains($0.id) }
        return unseen.isEmpty ? possible : unseen
    }
}
