import ApplicationServices
import Foundation

/// Sends one window's AX moves on its own queue and drops stale positions, so a slow app never backs up
/// the animation or the main thread. AX calls block until the target app answers.
final class WindowPositionPump: @unchecked Sendable {
    private let element: AXUIElement
    private let queue = DispatchQueue(label: "batuta.window-position-pump", qos: .userInteractive)
    private let lock = NSLock()
    private var latestPosition: CGPoint?
    private var isDraining = false

    init(element: AXUIElement) {
        self.element = element
    }

    func resize(to size: CGSize) {
        queue.async { self.element.setSize(size) }
    }

    func move(to position: CGPoint) {
        lock.lock()
        latestPosition = position
        let shouldStartDraining = !isDraining
        isDraining = true
        lock.unlock()

        if shouldStartDraining { queue.async { self.drainLatestPositions() } }
    }

    func land(on frame: CGRect, group: DispatchGroup) {
        group.enter()
        queue.async {
            self.lock.lock()
            self.latestPosition = nil
            self.lock.unlock()
            self.element.setFrame(frame, settleSize: true)
            group.leave()
        }
    }

    private func drainLatestPositions() {
        while true {
            lock.lock()
            guard let position = latestPosition else {
                isDraining = false
                lock.unlock()
                return
            }
            latestPosition = nil
            lock.unlock()
            element.setPosition(position)
        }
    }
}
