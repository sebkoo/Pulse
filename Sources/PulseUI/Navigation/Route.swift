/// A typed navigation destination. Typed rather than stringly-keyed so an
/// unhandled case is a compile error, not a silent dead link.
public enum Route: Hashable {
    /// City search → current weather for the picked place.
    case weatherSearch
    /// The full list of recent earthquakes.
    case quakes
}
