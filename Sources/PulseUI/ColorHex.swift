import SwiftUI

extension Color {
    /// Parse a `#RRGGBB` hex string; anything unparseable falls back to the
    /// given default — a bad brand color downgrades, never crashes.
    init(hex: String, fallback: Color = .accentColor) {
        var value = hex.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let rgb = UInt64(value, radix: 16) else {
            self = fallback
            return
        }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
