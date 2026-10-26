/// One resolved hand.
struct HandRecord: Sendable, Identifiable {
    let number: Int
    let picker: Side
    let category: Category
    let userCard: Player
    let cpuCard: Player
    let outcome: Outcome
    /// Cards sitting in the ruck after this hand (0 once someone has collected it).
    let ruckAfter: Int

    var id: Int { number }
    var userValue: Int { userCard.value(for: category) }
    var cpuValue: Int { cpuCard.value(for: category) }
}
