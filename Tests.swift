import Foundation

@main
struct Tests {
    static func main() throws {
        // A permission revocation must stop the helper; polling must never spawn duplicates.
        precondition(engineAction(enabled: true, permitted: true, running: false) == .start)
        precondition(engineAction(enabled: true, permitted: true, running: true) == .none)
        precondition(engineAction(enabled: true, permitted: false, running: false) == .none)
        precondition(engineAction(enabled: true, permitted: false, running: true) == .stop)
        precondition(engineAction(enabled: false, permitted: true, running: true) == .stop)
        precondition(engineAction(enabled: false, permitted: true, running: false) == .none)
        print("6 lifecycle checks passed")
        try runLocalizationChecks()
    }
}
