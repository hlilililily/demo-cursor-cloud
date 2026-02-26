import Foundation
import EventKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Represents a calendar group/source with associated calendars.
struct CalendarGroup: Identifiable, Hashable {
    let id: String
    var title: String
    var calendars: [CalendarInfo]

    struct CalendarInfo: Identifiable, Hashable {
        let id: String
        var title: String
        var color: Color
        var cgColor: CGColor
        var isVisible: Bool
        var sourceType: EKSourceType
        var isSubscribed: Bool
        var isImmutable: Bool

        init(from ekCalendar: EKCalendar, isVisible: Bool = true) {
            self.id = ekCalendar.calendarIdentifier
            self.title = ekCalendar.title
            self.cgColor = ekCalendar.cgColor
            self.color = Color(cgColor: ekCalendar.cgColor)
            self.isVisible = isVisible
            self.sourceType = ekCalendar.source?.sourceType ?? .local
            self.isSubscribed = ekCalendar.isSubscribed
            self.isImmutable = ekCalendar.isImmutable
        }

        init(
            id: String = UUID().uuidString,
            title: String,
            color: Color,
            isVisible: Bool = true
        ) {
            self.id = id
            self.title = title
            self.color = color
            #if canImport(UIKit)
            self.cgColor = UIColor(color).cgColor
            #else
            self.cgColor = NSColor(color).cgColor
            #endif
            self.isVisible = isVisible
            self.sourceType = .local
            self.isSubscribed = false
            self.isImmutable = false
        }
    }

    init(from source: EKSource, visibleCalendarIDs: Set<String>) {
        self.id = source.sourceIdentifier
        self.title = source.title
        self.calendars = source.calendars(for: .event)
            .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
            .map { CalendarInfo(from: $0, isVisible: visibleCalendarIDs.contains($0.calendarIdentifier)) }
    }

    init(id: String = UUID().uuidString, title: String, calendars: [CalendarInfo] = []) {
        self.id = id
        self.title = title
        self.calendars = calendars
    }
}
