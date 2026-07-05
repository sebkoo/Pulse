import SwiftUI
import PulseCore

/// The whole dashboard, driven entirely by `BrandConfig`:
/// the title and accent come from the brand, and the cards render in the
/// order `config.modules` asks for — unknown ids are simply skipped.
///
/// `DashboardView` never references a concrete provider; it renders whatever
/// `DashboardModule` descriptors it is given. That indirection is the
/// "zero UI changes" guarantee.
public struct DashboardView: View {
    private let config: BrandConfig
    private let modules: [DashboardModule]
    private let accent: Color

    public init(config: BrandConfig, modules: [DashboardModule]) {
        self.config = config
        self.modules = modules
        self.accent = Color(hex: config.accentColorHex, fallback: .blue)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                ForEach(orderedModules) { module in
                    ModuleCard(title: module.title, accent: accent) {
                        module.body()
                    }
                }
            }
            .padding(16)
        }
        .background(Color(hex: "#F4F5F7", fallback: .gray).opacity(0.6))
        .tint(accent)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(accent)
                .frame(width: 12, height: 12)
            Text(config.appName)
                .font(.largeTitle.bold())
            Spacer(minLength: 0)
        }
        .padding(.bottom, 2)
    }

    /// Config order wins; ids the catalog doesn't know are ignored.
    private var orderedModules: [DashboardModule] {
        config.modules.compactMap { id in
            modules.first { $0.id == id }
        }
    }
}
