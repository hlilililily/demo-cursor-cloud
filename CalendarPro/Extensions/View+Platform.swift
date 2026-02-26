import SwiftUI

extension View {
    /// Apply a modifier only on iOS.
    @ViewBuilder
    func iOS<Content: View>(_ modifier: (Self) -> Content) -> some View {
        #if os(iOS)
        modifier(self)
        #else
        self
        #endif
    }

    /// Apply a modifier only on macOS.
    @ViewBuilder
    func macOS<Content: View>(_ modifier: (Self) -> Content) -> some View {
        #if os(macOS)
        modifier(self)
        #else
        self
        #endif
    }

    /// Adaptive sheet presentation — popover on macOS, sheet on iOS.
    func adaptiveSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(macOS)
        self.popover(isPresented: isPresented) { content() }
        #else
        self.sheet(isPresented: isPresented) { content() }
        #endif
    }

    /// Card-style background used across the app.
    func calendarCard() -> some View {
        self
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
