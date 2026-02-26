import SwiftUI

extension Color {
    /// Preset calendar colors matching Apple Calendar's palette.
    static let calendarPresets: [(name: String, color: Color)] = [
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Blue", .blue),
        ("Purple", .purple),
        ("Brown", .brown),
        ("Pink", .pink),
        ("Teal", .teal),
        ("Indigo", .indigo),
        ("Cyan", .cyan),
        ("Mint", .mint),
    ]

    /// Convert Color to CGColor reliably.
    var cgColorValue: CGColor {
        #if canImport(UIKit)
        UIColor(self).cgColor
        #else
        NSColor(self).cgColor
        #endif
    }

    /// Create Color from a CGColor, with fallback.
    init(cgColor: CGColor?) {
        if let cg = cgColor {
            #if canImport(UIKit)
            self.init(uiColor: UIColor(cgColor: cg))
            #else
            self.init(nsColor: NSColor(cgColor: cg) ?? .systemBlue)
            #endif
        } else {
            self = .blue
        }
    }
}
