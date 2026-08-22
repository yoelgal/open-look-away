import Foundation

enum OfficeHours {
    static func contains(_ now: Date, _ settings: AppSettings, calendar: Calendar = .current) -> Bool {
        guard settings.officeHoursEnabled else { return true }
        let weekday = calendar.component(.weekday, from: now)
        if settings.officeWeekdaysOnly && (weekday == 1 || weekday == 7) { return false }
        let minutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let start = settings.officeStartHour * 60 + settings.officeStartMinute
        let end = settings.officeEndHour * 60 + settings.officeEndMinute
        if start == end { return true }
        if start < end { return minutes >= start && minutes < end }
        return minutes >= start || minutes < end
    }
}
