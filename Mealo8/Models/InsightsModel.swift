//  InsightsModel.swift
//  Mealo8

import Foundation
import SwiftData
import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Enums
// ─────────────────────────────────────────────────────────────────────────────

enum Timeframe: String, CaseIterable {
    case week  = "Week"
    case month = "Month"
}

enum MoodState: String, Codable, CaseIterable {
    case happy   = "Happy"
    case excited = "Excited"
    case sad     = "Sad"
    case tired   = "Tired"

    var color: Color {
        switch self {
        case .happy:   return Color("orange")
        case .excited: return Color("green")
        case .sad:     return Color(red: 0.6, green: 0.67, blue: 0.78)
        case .tired:   return Color("pink")
        }
    }

    var emoji: String {
        switch self {
        case .happy:   return "😊"
        case .excited: return "🤩"
        case .sad:     return "😔"
        case .tired:   return "😴"
        }
    }

    var label: String { rawValue }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SwiftData Models
// ─────────────────────────────────────────────────────────────────────────────

@Model
final class MealLog {
    var date: Date
    var mood: MoodState
    var note: String

    init(date: Date = Date(), mood: MoodState, note: String = "") {
        self.date = date
        self.mood = mood
        self.note = note
    }
}

/// Stored once during onboarding. Onboarding only asks for a name —
/// signupDate defaults to now, dailyMealGoal defaults to 3.
@Model
final class UserProfile {
    var name:          String
    var signupDate:    Date
    var dailyMealGoal: Int

    init(name: String, signupDate: Date = Date(), dailyMealGoal: Int = 3) {
        self.name          = name
        self.signupDate    = signupDate
        self.dailyMealGoal = dailyMealGoal
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Derived types (not persisted)
// ─────────────────────────────────────────────────────────────────────────────

struct DaySummary {
    let date:     Date
    let mood:     MoodState?
    let logCount: Int
    let goalMet:  Bool
}

struct Insight: Identifiable {
    let id   = UUID()
    let icon: String
    let text: String
}

struct InsightsPeriodData {
    let daySummaries:     [DaySummary]
    let insights:         [Insight]
    let patternHeadline:  String
    let patternSubtext:   String
    let goalProgress:     Double
    let goalProgressText: String
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Date Utilities
// ─────────────────────────────────────────────────────────────────────────────

enum MealoDate {

    static var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.locale       = .current
        c.timeZone     = .current
        return c
    }()

    static func periodLabel(for date: Date, timeframe: Timeframe) -> String {
        switch timeframe {
        case .week:
            let (s, e) = weekBounds(for: date)
            return "\(formatted(s, format: "MMM d")) – \(formatted(e, format: "MMM d"))"
        case .month:
            return formatted(date, format: "MMMM yyyy")
        }
    }

    static func navigate(_ date: Date, timeframe: Timeframe, forward: Bool) -> Date {
        let v = forward ? 1 : -1
        switch timeframe {
        case .week:  return calendar.date(byAdding: .weekOfYear, value: v, to: date) ?? date
        case .month: return calendar.date(byAdding: .month,      value: v, to: date) ?? date
        }
    }

    static func monthGrid(for date: Date) -> [Date?] {
        guard
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
            let range      = calendar.range(of: .day, in: .month, for: monthStart)
        else { return [] }

        let days: [Date?] = range.compactMap {
            calendar.date(byAdding: .day, value: $0 - 1, to: monthStart)
        }
        var weekday = calendar.component(.weekday, from: monthStart) - calendar.firstWeekday
        if weekday < 0 { weekday += 7 }
        return Array(repeating: nil, count: weekday) + days
    }

    static func weekDays(for date: Date) -> [Date] {
        let comps  = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let monday = calendar.date(from: comps) ?? date
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    static func weekBounds(for date: Date) -> (Date, Date) {
        let days = weekDays(for: date)
        return (days.first ?? date, days.last ?? date)
    }

    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    static func isOnOrAfter(_ date: Date, signupDate: Date) -> Bool {
        calendar.startOfDay(for: date) >= calendar.startOfDay(for: signupDate)
    }

    static func isNotFuture(_ date: Date) -> Bool {
        calendar.startOfDay(for: date) <= calendar.startOfDay(for: Date())
    }

    static func formatted(_ date: Date, format: String) -> String {
        let f = DateFormatter()
        f.dateFormat = format
        f.calendar   = calendar
        f.timeZone   = .current
        return f.string(from: date)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Insights Repository
// ─────────────────────────────────────────────────────────────────────────────

struct InsightsRepository {

    static func periodData(
        logs:      [MealLog],
        profile:   UserProfile,
        anchor:    Date,
        timeframe: Timeframe
    ) -> InsightsPeriodData {

        let periodDays = days(for: anchor, timeframe: timeframe)
            .filter {
                MealoDate.isOnOrAfter($0, signupDate: profile.signupDate) &&
                MealoDate.isNotFuture($0)
            }

        let summaries = periodDays.map { daySummary(day: $0, logs: logs, goal: profile.dailyMealGoal) }

        return InsightsPeriodData(
            daySummaries:     summaries,
            insights:         insights(from: logs, period: periodDays),
            patternHeadline:  patternHeadline(from: logs, period: periodDays),
            patternSubtext:   patternSubtext(from: logs, period: periodDays),
            goalProgress:     goalProgress(summaries: summaries),
            goalProgressText: progressText(summaries: summaries)
        )
    }

    static func calendarGrid(anchor: Date, timeframe: Timeframe) -> [Date?] {
        switch timeframe {
        case .month: return MealoDate.monthGrid(for: anchor)
        case .week:  return MealoDate.weekDays(for: anchor).map { Optional($0) }
        }
    }

    private static func days(for anchor: Date, timeframe: Timeframe) -> [Date] {
        switch timeframe {
        case .week:  return MealoDate.weekDays(for: anchor)
        case .month: return MealoDate.monthGrid(for: anchor).compactMap { $0 }
        }
    }

    private static func daySummary(day: Date, logs: [MealLog], goal: Int) -> DaySummary {
        let dayLogs = logs.filter { MealoDate.isSameDay($0.date, day) }
        guard !dayLogs.isEmpty else {
            return DaySummary(date: day, mood: nil, logCount: 0, goalMet: false)
        }
        let dominant = Dictionary(grouping: dayLogs, by: { $0.mood })
            .max(by: { $0.value.count < $1.value.count })?.key
        return DaySummary(date: day, mood: dominant,
                          logCount: dayLogs.count, goalMet: dayLogs.count >= goal)
    }

    private static func goalProgress(summaries: [DaySummary]) -> Double {
        guard !summaries.isEmpty else { return 0 }
        return Double(summaries.filter { $0.logCount > 0 }.count) / Double(summaries.count)
    }

    private static func progressText(summaries: [DaySummary]) -> String {
        switch goalProgress(summaries: summaries) {
        case 0:       return "Start logging today to build your rhythm."
        case ..<0.3:  return "Every small step counts. Keep going!"
        case ..<0.6:  return "You're finding your rhythm — keep it up."
        case ..<0.85: return "You're building a beautiful rhythm. Keep going!"
        default:      return "Incredible consistency. You're glowing."
        }
    }

    private static func peakHour(from logs: [MealLog], period: [Date]) -> Int? {
        let periodLogs = logs.filter { log in period.contains { MealoDate.isSameDay(log.date, $0) } }
        guard !periodLogs.isEmpty else { return nil }
        let hours = periodLogs.map { MealoDate.calendar.component(.hour, from: $0.date) }
        return hours.reduce(0, +) / hours.count
    }

    static func patternHeadline(from logs: [MealLog], period: [Date]) -> String {
        guard let avg = peakHour(from: logs, period: period) else {
            return "Log your first meal to see your pattern."
        }
        switch avg {
        case 5..<11:  return "Mornings were your strongest nourishment window."
        case 11..<15: return "Afternoons were your strongest nourishment window."
        case 15..<19: return "Late afternoons are when you showed up most."
        default:      return "Evenings are when you nourish yourself most."
        }
    }

    static func patternSubtext(from logs: [MealLog], period: [Date]) -> String {
        guard let avg = peakHour(from: logs, period: period) else {
            return "Log your first meal and we'll reflect your pattern here."
        }
        switch avg {
        case 5..<11:  return "You showed up for yourself most between 7am–10am."
        case 11..<15: return "You showed up for yourself most between 12pm–3pm."
        case 15..<19: return "You showed up for yourself most between 3pm–6pm."
        default:      return "You showed up for yourself most between 6pm–9pm."
        }
    }

    private static func insights(from logs: [MealLog], period: [Date]) -> [Insight] {
        let periodLogs = logs.filter { log in period.contains { MealoDate.isSameDay(log.date, $0) } }

        guard !periodLogs.isEmpty else {
            return [Insight(icon: "✨", text: "Start logging meals to unlock your personal insights.")]
        }

        var result: [Insight] = []

        let hours   = periodLogs.map { MealoDate.calendar.component(.hour, from: $0.date) }
        let avgHour = hours.reduce(0, +) / hours.count
        switch avgHour {
        case 5..<11:
            result.append(Insight(icon: "🌤️", text: "Morning check-ins helped you stay more consistent."))
        case 11..<15:
            result.append(Insight(icon: "☀️",  text: "You tend to nourish yourself later on busier days."))
        case 15..<19:
            result.append(Insight(icon: "🌅",  text: "Afternoons are when you showed up most for yourself."))
        default:
            result.append(Insight(icon: "🌙",  text: "Evening nourishment helps you end the day with more energy."))
        }

        let moodCounts = Dictionary(grouping: periodLogs, by: { $0.mood }).mapValues { $0.count }
        if let top = moodCounts.max(by: { $0.value < $1.value }),
           Double(top.value) / Double(periodLogs.count) > 0.40 {
            switch top.key {
            case .happy, .excited:
                result.append(Insight(icon: "🌤️", text: "You showed up with positive energy on most days — keep that warmth."))
            case .tired:
                result.append(Insight(icon: "🌙", text: "Rest days are part of the rhythm. Be gentle with yourself."))
            case .sad:
                result.append(Insight(icon: "🌱", text: "Nourishing yourself on hard days takes real courage."))
            }
        }

        let loggedDays = period.filter { day in
            periodLogs.contains { MealoDate.isSameDay($0.date, day) }
        }.count
        let rate = Double(loggedDays) / Double(max(period.count, 1))
        if rate >= 0.7 {
            result.append(Insight(icon: "☀️", text: "You checked in on \(Int(rate * 100))% of days — your rhythm is really growing."))
        } else if rate >= 0.4 {
            result.append(Insight(icon: "🌤️", text: "You logged on \(loggedDays) out of \(period.count) days. Small steps add up."))
        } else {
            result.append(Insight(icon: "🌙", text: "A few check-ins is still a win. Every log counts."))
        }

        return result
    }

    static func previewInsight(logs: [MealLog], profile: UserProfile) -> String {
        let today = Date()
        let last7 = (0..<7).compactMap { MealoDate.calendar.date(byAdding: .day, value: -$0, to: today) }
        let recent = logs.filter { log in
            last7.contains { MealoDate.isSameDay(log.date, $0) } &&
            MealoDate.isOnOrAfter(log.date, signupDate: profile.signupDate)
        }
        guard !recent.isEmpty else {
            return "Log your first meal and we'll reflect your rhythm here."
        }
        return patternHeadline(from: recent, period: last7)
    }
}
