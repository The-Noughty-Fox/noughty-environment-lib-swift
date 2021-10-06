//
//  Formatters+Extensions.swift
//  
//
//  Created by Lisnic Victor on 22.09.2021.
//

import Foundation

public extension DateFormatter {
    static let relativeDayFormatter = DateFormatter()
        .set(\.dateStyle, .short)
        .set(\.timeStyle, .none)
        .set(\.doesRelativeDateFormatting, true)

    static let weekdayFormatter = DateFormatter()
        .set(\.dateFormat, "EEEE")

    static let monthFormatter = DateFormatter()
        .set(\.dateFormat, "MMMM yyyy")
}

public extension NumberFormatter {
    static let ordinalFormatter = NumberFormatter()
        .set(\.numberStyle, .ordinal)
}

public extension Date {
    var formattedMonth: String {  DateFormatter.monthFormatter.string(from: self) }

    var formattedDay: String {
        if self > beginningOfYesterday {
            return DateFormatter.relativeDayFormatter.string(from: self)
        }
        let day = NumberFormatter.ordinalFormatter.string(from: NSNumber(integerLiteral: Calendar.current.component(.day, from: self)))
        let weekday = DateFormatter.weekdayFormatter.string(from: self)
        return day.map { [$0, weekday] }?.joined(separator: ", ") ?? weekday
    }

    var beginningOfYesterday: Date { Calendar.current.startOfDay(for: Date()).addingTimeInterval(-24 * 60 * 60) }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func isBefore(date: Date, components: Set<Calendar.Component>) -> Bool {
        self.round(to: components)
            .compare(date.round(to: components)) == ComparisonResult.orderedAscending
    }

    func round(to components: Set<Calendar.Component>) -> Date {
        let dateComponents = Calendar.current.dateComponents(components, from: self)
        return Calendar.current.date(from: dateComponents)!
    }
}
