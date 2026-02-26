import SwiftUI

@main
struct CalendarProApp: App {
    @State private var viewModel = CalendarViewModel()

    var body: some Scene {
        WindowGroup {
            MainView(viewModel: viewModel)
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 750)
        #endif

        #if os(macOS)
        Settings {
            SettingsView(viewModel: viewModel)
                .frame(minWidth: 450, minHeight: 500)
        }
        #endif
    }
}
