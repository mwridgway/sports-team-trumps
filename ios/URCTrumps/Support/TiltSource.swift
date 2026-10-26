import CoreMotion
import SwiftUI

/// Device tilt, shared by every foil card. Starts on first use.
@MainActor
final class TiltSource {
    static let shared = TiltSource()
    private let manager = CMMotionManager()
    private(set) var tilt: Double = 0
    private var watchers = 0

    func start() {
        watchers += 1
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let roll = motion?.attitude.roll else { return }
            MainActor.assumeIsolated { self?.tilt = max(-1, min(1, roll)) }
        }
    }

    func stop() {
        watchers -= 1
        if watchers <= 0 { manager.stopDeviceMotionUpdates() }
    }
}
