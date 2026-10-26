/// Sorted value lists per category across the whole URC pool, for percentile ranking.
struct StatBook: Sendable {
    private let sorted: [String: [Int]]

    init(players: [Player], categories: [Category]) {
        var map: [String: [Int]] = [:]
        for category in categories {
            map[category.key] = players.map { $0.value(for: category) }.sorted()
        }
        sorted = map
    }

    /// Share of the pool this value beats, with ties counted as half (0...1).
    func percentile(of value: Int, in category: Category) -> Double {
        guard let values = sorted[category.key], !values.isEmpty else { return 0 }
        let below = lowerBound(values, value)
        let belowOrEqual = lowerBound(values, value + 1)
        return (Double(below) + Double(belowOrEqual - below) / 2) / Double(values.count)
    }

    /// Index of the first element >= target.
    private func lowerBound(_ values: [Int], _ target: Int) -> Int {
        var low = 0, high = values.count
        while low < high {
            let mid = (low + high) / 2
            if values[mid] < target { low = mid + 1 } else { high = mid }
        }
        return low
    }
}
