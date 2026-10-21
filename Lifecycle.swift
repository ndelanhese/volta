import Foundation

enum EngineAction: Equatable {
    case start, stop, none
}

func engineAction(enabled: Bool, permitted: Bool, running: Bool) -> EngineAction {
    let wanted = enabled && permitted
    if running && !wanted { return .stop }
    if wanted && !running { return .start }
    return .none
}
