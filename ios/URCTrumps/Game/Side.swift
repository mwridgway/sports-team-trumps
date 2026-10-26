enum Side: Sendable {
    case user, cpu

    var other: Side { self == .user ? .cpu : .user }
}
