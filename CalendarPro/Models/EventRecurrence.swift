import Foundation
import EventKit

/// Represents an event recurrence rule.
struct EventRecurrence: Identifiable, Hashable {
    let id = UUID()
    var frequency: Frequency
    var interval: Int
    var daysOfWeek: [DayOfWeek]
    var daysOfMonth: [Int]
    var monthsOfYear: [Int]
    var endRule: EndRule?

    enum Frequency: Int, CaseIterable, Identifiable {
        case daily = 0
        case weekly = 1
        case monthly = 2
        case yearly = 3

        var id: Int { rawValue }

        var label: String {
            switch self {
            case .daily: "Daily"
            case .weekly: "Weekly"
            case .monthly: "Monthly"
            case .yearly: "Yearly"
            }
        }
    }

    enum DayOfWeek: Int, CaseIterable, Identifiable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7

        var id: Int { rawValue }

        var shortLabel: String {
            switch self {
            case .sunday: "Sun"
            case .monday: "Mon"
            case .tuesday: "Tue"
            case .wednesday: "Wed"
            case .thursday: "Thu"
            case .friday: "Fri"
            case .saturday: "Sat"
            }
        }

        var label: String {
            switch self {
            case .sunday: "Sunday"
            case .monday: "Monday"
            case .tuesday: "Tuesday"
            case .wednesday: "Wednesday"
            case .thursday: "Thursday"
            case .friday: "Friday"
            case .saturday: "Saturday"
            }
        }

        var ekDay: EKWeekday {
            EKWeekday(rawValue: rawValue)!
        }
    }

    enum EndRule: Hashable {
        case endDate(Date)
        case occurrenceCount(Int)
    }

    init(
        frequency: Frequency = .weekly,
        interval: Int = 1,
        daysOfWeek: [DayOfWeek] = [],
        daysOfMonth: [Int] = [],
        monthsOfYear: [Int] = [],
        endRule: EndRule? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.daysOfMonth = daysOfMonth
        self.monthsOfYear = monthsOfYear
        self.endRule = endRule
    }

    init(from ekRule: EKRecurrenceRule) {
        self.frequency = Frequency(rawValue: ekRule.frequency.rawValue) ?? .weekly
        self.interval = ekRule.interval
        self.daysOfWeek = ekRule.daysOfTheWeek?.compactMap { DayOfWeek(rawValue: $0.dayOfTheWeek.rawValue) } ?? []
        self.daysOfMonth = ekRule.daysOfTheMonth?.map { $0.intValue } ?? []
        self.monthsOfYear = ekRule.monthsOfTheYear?.map { $0.intValue } ?? []

        if let end = ekRule.recurrenceEnd {
            if let endDate = end.endDate {
                self.endRule = .endDate(endDate)
            } else if end.occurrenceCount > 0 {
                self.endRule = .occurrenceCount(end.occurrenceCount)
            } else {
                self.endRule = nil
            }
        } else {
            self.endRule = nil
        }
    }

    func toEKRecurrenceRule() -> EKRecurrenceRule {
        let ekFrequency: EKRecurrenceFrequency
        switch frequency {
        case .daily: ekFrequency = .daily
        case .weekly: ekFrequency = .weekly
        case .monthly: ekFrequency = .monthly
        case .yearly: ekFrequency = .yearly
        }

        let ekDays: [EKRecurrenceDayOfWeek]? = daysOfWeek.isEmpty ? nil :
            daysOfWeek.map { EKRecurrenceDayOfWeek($0.ekDay) }
        let ekDaysOfMonth: [NSNumber]? = daysOfMonth.isEmpty ? nil :
            daysOfMonth.map { NSNumber(value: $0) }
        let ekMonths: [NSNumber]? = monthsOfYear.isEmpty ? nil :
            monthsOfYear.map { NSNumber(value: $0) }

        let ekEnd: EKRecurrenceEnd?
        switch endRule {
        case .endDate(let date):
            ekEnd = EKRecurrenceEnd(end: date)
        case .occurrenceCount(let count):
            ekEnd = EKRecurrenceEnd(occurrenceCount: count)
        case nil:
            ekEnd = nil
        }

        return EKRecurrenceRule(
            recurrenceWith: ekFrequency,
            interval: interval,
            daysOfTheWeek: ekDays,
            daysOfTheMonth: ekDaysOfMonth,
            monthsOfTheYear: ekMonths,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: ekEnd
        )
    }

    var displayText: String {
        if interval == 1 {
            switch frequency {
            case .daily: return "Every Day"
            case .weekly:
                if daysOfWeek.isEmpty { return "Every Week" }
                let days = daysOfWeek.map(\.shortLabel).joined(separator: ", ")
                return "Every Week on \(days)"
            case .monthly: return "Every Month"
            case .yearly: return "Every Year"
            }
        }
        let unit: String
        switch frequency {
        case .daily: unit = "days"
        case .weekly: unit = "weeks"
        case .monthly: unit = "months"
        case .yearly: unit = "years"
        }
        return "Every \(interval) \(unit)"
    }
}

/// Represents an alarm/reminder for an event.
struct EventAlarm: Identifiable, Hashable {
    let id = UUID()
    var offset: TimeInterval
    var isAbsolute: Bool
    var absoluteDate: Date?

    static let presets: [(label: String, offset: TimeInterval)] = [
        ("At time of event", 0),
        ("5 minutes before", -5 * 60),
        ("10 minutes before", -10 * 60),
        ("15 minutes before", -15 * 60),
        ("30 minutes before", -30 * 60),
        ("1 hour before", -3600),
        ("2 hours before", -7200),
        ("1 day before", -86400),
        ("2 days before", -172800),
        ("1 week before", -604800),
    ]

    init(offset: TimeInterval = -15 * 60) {
        self.offset = offset
        self.isAbsolute = false
        self.absoluteDate = nil
    }

    init(absoluteDate: Date) {
        self.offset = 0
        self.isAbsolute = true
        self.absoluteDate = absoluteDate
    }

    init(from ekAlarm: EKAlarm) {
        if let date = ekAlarm.absoluteDate {
            self.offset = 0
            self.isAbsolute = true
            self.absoluteDate = date
        } else {
            self.offset = ekAlarm.relativeOffset
            self.isAbsolute = false
            self.absoluteDate = nil
        }
    }

    func toEKAlarm() -> EKAlarm {
        if isAbsolute, let date = absoluteDate {
            return EKAlarm(absoluteDate: date)
        }
        return EKAlarm(relativeOffset: offset)
    }

    var displayText: String {
        if isAbsolute, let date = absoluteDate {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        if let preset = Self.presets.first(where: { $0.offset == offset }) {
            return preset.label
        }
        let minutes = Int(abs(offset) / 60)
        if minutes < 60 { return "\(minutes) minutes before" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours) hour\(hours == 1 ? "" : "s") before" }
        let days = hours / 24
        return "\(days) day\(days == 1 ? "" : "s") before"
    }
}
