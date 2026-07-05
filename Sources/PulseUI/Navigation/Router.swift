import Observation

/// The coordinator: it owns the navigation path and nothing else. Views push
/// routes onto it; the `NavigationStack` renders them. Keeping navigation state
/// out of the views is the whole point — a view says "go here," not "how."
@Observable
@MainActor
public final class Router {
    public var path: [Route] = []

    public init() {}

    public func push(_ route: Route) {
        path.append(route)
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func popToRoot() {
        path.removeAll()
    }
}
