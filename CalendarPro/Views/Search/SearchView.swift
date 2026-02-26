import SwiftUI

/// Search view for finding events by title, location, or notes.
struct SearchView: View {
    @Bindable var viewModel: CalendarViewModel
    @State private var query = ""
    @State private var results: [CalendarEvent] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchField
                Divider()
                resultsList
            }
            .navigationTitle("Search")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            #endif
        }
        .frame(minWidth: 350, minHeight: 400)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search events…", text: $query)
                .textFieldStyle(.plain)
                .onChange(of: query) { performSearch() }
            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var resultsList: some View {
        if results.isEmpty && !query.isEmpty {
            ContentUnavailableView.search(text: query)
        } else if results.isEmpty {
            ContentUnavailableView(
                "Search Events",
                systemImage: "magnifyingglass",
                description: Text("Search by title, location, or notes.")
            )
        } else {
            List(results) { event in
                EventRow(event: event, showDate: true)
                    .onTapGesture {
                        viewModel.selectedEvent = event
                        viewModel.selectDate(event.startDate)
                        dismiss()
                    }
            }
            .listStyle(.plain)
        }
    }

    private func performSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        let range = viewModel.eventKitManager.yearRange(around: Date())
        results = viewModel.eventKitManager.searchEvents(
            query: query,
            from: range.start,
            to: range.end
        )
    }
}
