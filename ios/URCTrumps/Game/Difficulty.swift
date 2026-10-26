enum Difficulty: String, CaseIterable, Identifiable, Sendable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var id: String { rawValue }
}
