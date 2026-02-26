import SwiftUI

/// Root view that assembles the navigation bar, sidebar, and calendar content.
struct MainView: View {
    @State var viewModel: CalendarViewModel
    @Namespace private var calendarNamespace

    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    // MARK: - macOS Layout (NavigationSplitView)

    #if os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView(
            columnVisibility: Binding(
                get: { viewModel.showingSidebar ? .all : .detailOnly },
                set: { viewModel.showingSidebar = $0 != .detailOnly }
            )
        ) {
            SidebarView(viewModel: viewModel)
        } detail: {
            calendarContent
                .toolbar { toolbarContent }
        }
        .sheet(item: $viewModel.selectedEvent) { event in
            EventDetailView(
                event: event,
                onEdit: { viewModel.editEvent(event) },
                onDelete: { span in viewModel.deleteEvent(event, span: span) },
                onDismiss: { viewModel.selectedEvent = nil }
            )
        }
        .sheet(isPresented: $viewModel.showingNewEvent) { eventEditorSheet }
        .sheet(isPresented: $viewModel.showingEventEditor) { eventEditorSheet }
        .sheet(isPresented: $viewModel.showingSearch) {
            SearchView(viewModel: viewModel)
        }
        .onAppear { requestAccessAndLoad() }
    }
    #endif

    // MARK: - iOS Layout (NavigationStack + TabView-like)

    #if os(iOS)
    private var iOSLayout: some View {
        NavigationStack {
            calendarContent
                .toolbar { toolbarContent }
                .sheet(item: $viewModel.selectedEvent) { event in
                    EventDetailView(
                        event: event,
                        onEdit: { viewModel.editEvent(event) },
                        onDelete: { span in viewModel.deleteEvent(event, span: span) },
                        onDismiss: { viewModel.selectedEvent = nil }
                    )
                }
                .sheet(isPresented: $viewModel.showingNewEvent) { eventEditorSheet }
                .sheet(isPresented: $viewModel.showingEventEditor) { eventEditorSheet }
                .sheet(isPresented: $viewModel.showingSearch) {
                    SearchView(viewModel: viewModel)
                }
                .sheet(isPresented: $viewModel.showingSidebar) {
                    NavigationStack {
                        SidebarView(viewModel: viewModel)
                            .navigationTitle("Calendars")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Done") { viewModel.showingSidebar = false }
                                }
                            }
                    }
                }
                .sheet(isPresented: $viewModel.showingSettings) {
                    SettingsView(viewModel: viewModel)
                }
        }
        .onAppear { requestAccessAndLoad() }
    }
    #endif

    // MARK: - Calendar Content

    @ViewBuilder
    private var calendarContent: some View {
        VStack(spacing: 0) {
            switch viewModel.viewMode {
            case .day:
                DayView(viewModel: viewModel)
            case .week:
                WeekView(viewModel: viewModel)
            case .month:
                MonthView(viewModel: viewModel, namespace: calendarNamespace)
            case .year:
                YearView(viewModel: viewModel)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.viewMode)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            HStack(spacing: 12) {
                Button {
                    viewModel.showingSidebar = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                }
            }
        }
        #endif

        ToolbarItem(placement: .principal) {
            HStack(spacing: 12) {
                Button {
                    withAnimation { viewModel.navigateBackward() }
                } label: {
                    Image(systemName: "chevron.left")
                }

                Text(viewModel.navigationTitle)
                    .font(.headline)
                    .lineLimit(1)

                Button {
                    withAnimation { viewModel.navigateForward() }
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
        }

        ToolbarItemGroup(placement: .automatic) {
            Button("Today") {
                withAnimation { viewModel.goToToday() }
            }

            Picker("View", selection: Binding(
                get: { viewModel.viewMode },
                set: { viewModel.setViewMode($0) }
            )) {
                ForEach(CalendarViewModel.ViewMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 250)

            Button {
                viewModel.showingSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
            }

            Button {
                viewModel.createNewEvent()
            } label: {
                Image(systemName: "plus")
            }

            #if os(iOS)
            Button {
                viewModel.showingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            #endif
        }
    }

    // MARK: - Event Editor Sheet

    @ViewBuilder
    private var eventEditorSheet: some View {
        let allCalendars = viewModel.eventKitManager.calendarGroups()
            .flatMap(\.calendars)
            .filter { !$0.isImmutable }

        EventEditorView(
            event: viewModel.editingEvent,
            defaultCalendarID: viewModel.eventKitManager.defaultCalendar?.calendarIdentifier ?? "",
            calendars: allCalendars,
            onSave: { event in
                viewModel.saveEvent(event)
            },
            onCancel: {
                viewModel.showingNewEvent = false
                viewModel.showingEventEditor = false
                viewModel.editingEvent = nil
            }
        )
    }

    // MARK: - Lifecycle

    private func requestAccessAndLoad() {
        Task {
            let granted = await viewModel.eventKitManager.requestAccess()
            if granted {
                await MainActor.run { viewModel.loadEvents() }
            }
            _ = await viewModel.notificationManager.requestAuthorization()
        }
    }
}
