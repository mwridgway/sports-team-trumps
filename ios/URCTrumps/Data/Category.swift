import Foundation

/// A trump category (config-driven from urc.json).
struct Category: Codable, Hashable, Identifiable, Sendable {
    let key: String
    let label: String
    let unit: String?
    var id: String { key }
}
