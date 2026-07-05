import SwiftUI

/// A dashboard entry the UI can render without knowing anything about the
/// data source behind it. Adding a provider means adding one descriptor —
/// `DashboardView` itself never changes.
public struct DashboardModule: Identifiable {
    public let id: String
    public let title: String
    private let content: () -> AnyView

    public init(id: String, title: String, @ViewBuilder content: @escaping () -> some View) {
        self.id = id.lowercased()
        self.title = title
        let builder = content
        self.content = { AnyView(builder()) }
    }

    @ViewBuilder
    func body() -> some View {
        content()
    }
}
