import SwiftUI

/// A dashboard entry the UI can render without knowing anything about the
/// data source behind it. Adding a provider means adding one descriptor —
/// `DashboardView` itself never changes.
public struct DashboardModule: Identifiable {
    public let id: String
    public let title: String
    /// Where tapping this module's card navigates, if anywhere. `nil` renders a
    /// plain, non-tappable card (previews and screenshots leave it nil).
    public var route: Route?
    private let content: () -> AnyView

    public init(id: String, title: String, route: Route? = nil, @ViewBuilder content: @escaping () -> some View) {
        self.id = id.lowercased()
        self.title = title
        self.route = route
        let builder = content
        self.content = { AnyView(builder()) }
    }

    @ViewBuilder
    func body() -> some View {
        content()
    }
}
