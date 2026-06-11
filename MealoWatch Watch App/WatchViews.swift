//
//  WatchViews.swift
//  MealoWatch Watch App
//

import SwiftUI
import SwiftData
import UserNotifications

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Watch-only Models
// ─────────────────────────────────────────────────────────────────────────────

enum WatchMood: String, Codable {
    case happy, excited, sad, tired
}

@Model
final class WatchMealLog {
    var date:     Date
    var mood:     WatchMood
    var mealName: String

    init(date: Date = Date(), mood: WatchMood, mealName: String) {
        self.date     = date
        self.mood     = mood
        self.mealName = mealName
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Character Mood Engine (Duolingo-style)
// ─────────────────────────────────────────────────────────────────────────────

enum CharacterMood: String {
    case happy      // Logged on track — full color, big bounce
    case content    // Slightly behind — full color, gentle bounce
    case tired      // Missing meals — desaturated, slow sway
    case sad        // Way behind / no logs — grayscale, droopy, no bounce

    /// How many meals the user *should* have logged by this hour
    static func expectedMeals(byHour hour: Int) -> Int {
        switch hour {
        case 0..<9:   return 0          // too early, no pressure
        case 9..<13:  return 1          // breakfast expected
        case 13..<16: return 2          // lunch expected
        case 16..<19: return 3          // snack expected
        default:      return 4          // dinner expected
        }
    }

    static func current(todayCount: Int, streak: Int) -> CharacterMood {
        let hour     = Calendar.current.component(.hour, from: Date())
        let expected = expectedMeals(byHour: hour)

        // Before 9am — always happy, no pressure
        if expected == 0 { return .happy }

        let ratio = Double(todayCount) / Double(max(expected, 1))

        switch ratio {
        case 0.75...:  return .happy      // on track or ahead
        case 0.5..<0.75: return .content  // slightly behind
        case 0.25..<0.5: return .tired    // falling behind
        default:
            // Zero logs + past lunch = sad
            if todayCount == 0 && hour >= 13 { return .sad }
            return .tired
        }
    }

    var message: String {
        switch self {
        case .happy:   return "You're doing great!"
        case .content: return "Don't forget to eat!"
        case .tired:   return "I'm getting hungry..."
        case .sad:     return "I miss you...\nLet's eat something"
        }
    }

    var subtitle: String {
        switch self {
        case .happy:   return "Keep it up!"
        case .content: return "A meal would be nice"
        case .tired:   return "Feed me please..."
        case .sad:     return "Just one meal?"
        }
    }

    var imageName: String {
        switch self {
        case .happy:   return "ch1"
        case .content: return "ch2"
        case .tired:   return "ch3"
        case .sad:     return "ch4"
        }
    }

    var bounceAmount: CGFloat {
        switch self {
        case .happy:   return -10
        case .content: return -5
        case .tired:   return -2
        case .sad:     return 0
        }
    }

    var rotation: Double {
        switch self {
        case .happy, .content: return 0
        case .tired:   return 5     // slight tilt
        case .sad:     return 10    // droopy tilt
        }
    }

}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Notification Manager
// ─────────────────────────────────────────────────────────────────────────────

final class MealNotificationManager {
    static let shared = MealNotificationManager()

    private let mealTimes: [(name: String, hour: Int, minute: Int)] = [
        ("Breakfast", 8,  0),
        ("Lunch",     12, 30),
        ("Snack",     15, 0),
        ("Dinner",    18, 30),
    ]

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func scheduleMealReminders() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for meal in mealTimes {
            let content = UNMutableNotificationContent()
            content.title = "Time for \(meal.name)!"
            content.body  = "Your Mealo orange is waiting for you. Don't let it get sad!"
            content.sound = .default

            var dc = DateComponents()
            dc.hour   = meal.hour
            dc.minute = meal.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let request = UNNotificationRequest(
                identifier: "mealo.\(meal.name.lowercased())",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }

        // Guilt-trip reminder if no meals by 2pm
        let guiltContent = UNMutableNotificationContent()
        guiltContent.title = "Your orange is getting sad..."
        guiltContent.body  = "You haven't logged any meals today. Even a small snack counts!"
        guiltContent.sound = .default

        var guiltDC = DateComponents()
        guiltDC.hour   = 14
        guiltDC.minute = 0

        let guiltTrigger = UNCalendarNotificationTrigger(dateMatching: guiltDC, repeats: true)
        let guiltRequest = UNNotificationRequest(
            identifier: "mealo.guilt",
            content: guiltContent,
            trigger: guiltTrigger
        )
        center.add(guiltRequest)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Colors
// ─────────────────────────────────────────────────────────────────────────────

private let wOrange = Color(red: 0.91, green: 0.45, blue: 0.32)
private let wGreen  = Color(red: 0.55, green: 0.72, blue: 0.55)
private let wYellow = Color(red: 0.97, green: 0.85, blue: 0.45)
private let wPink   = Color(red: 0.98, green: 0.82, blue: 0.82)

private let defaultGoal = 4

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Shared header
// ─────────────────────────────────────────────────────────────────────────────

private struct WatchHeader: View {
    let title: String
    var body: some View {
        HStack {
            Spacer()
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(wOrange)
        }
        .padding(.horizontal, 10)
        .padding(.top, 2)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Character View (reusable)
// ─────────────────────────────────────────────────────────────────────────────

private struct MealoCharacter: View {
    let mood: CharacterMood
    let size: CGFloat
    @State private var animating = false

    var body: some View {
        Image(mood.imageName)
            .resizable().scaledToFit()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(animating ? mood.rotation : -mood.rotation))
            .offset(y: animating ? mood.bounceAmount : 0)
            .animation(
                mood == .sad
                    ? nil
                    : .interpolatingSpring(stiffness: mood == .happy ? 130 : 60, damping: mood == .happy ? 6 : 10)
                      .repeatForever(autoreverses: true),
                value: animating
            )
            .onAppear { animating = true }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 1. State View — character reacts to your logging
// ─────────────────────────────────────────────────────────────────────────────

struct WatchStateView: View {
    @Query(sort: \WatchMealLog.date, order: .reverse) private var logs: [WatchMealLog]

    private var todayCount: Int {
        logs.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    private var streak: Int {
        var count = 0
        var day = Calendar.current.startOfDay(for: Date())
        while logs.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            count += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return count
    }

    private var mood: CharacterMood {
        .current(todayCount: todayCount, streak: streak)
    }

    var body: some View {
        VStack(spacing: 6) {
            WatchHeader(title: "State")

            MealoCharacter(mood: mood, size: 100)

            Text(mood.message)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(mood.subtitle)
                .font(.system(size: 11))
                .foregroundColor(mood == .sad ? .gray : wOrange)
        }
        .padding(.bottom, 8)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 2. Log Food View
// ─────────────────────────────────────────────────────────────────────────────

struct WatchLogFoodView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WatchMealLog.date, order: .reverse) private var logs: [WatchMealLog]

    private struct MealOption: Identifiable {
        let id     = UUID()
        let label:  String
        let symbol: String
        let color:  Color
        let mood:   WatchMood
    }

    private let options: [MealOption] = [
        MealOption(label: "Breakfast", symbol: "sun.horizon.fill",                  color: wYellow, mood: .happy),
        MealOption(label: "Lunch",     symbol: "fork.knife",                        color: wGreen,  mood: .excited),
        MealOption(label: "Dinner",    symbol: "moon.stars.fill",                   color: wOrange, mood: .happy),
        MealOption(label: "Snack",     symbol: "takeoutbag.and.cup.and.straw.fill", color: wPink,   mood: .excited),
    ]

    @State private var justLogged: String? = nil
    @State private var confirmMsg: String? = nil

    private func isLoggedToday(_ label: String) -> Bool {
        logs.contains { $0.mealName == label && Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        VStack(spacing: 4) {
            WatchHeader(title: "Log Food")
            Text("What did you have?")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 5),
                GridItem(.flexible(), spacing: 5)
            ], spacing: 5) {
                ForEach(options) { meal in
                    let active = justLogged == meal.label || isLoggedToday(meal.label)
                    Button { log(meal) } label: {
                        VStack(spacing: 3) {
                            ZStack {
                                Image(systemName: meal.symbol)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(active ? .white : Color.black.opacity(0.7))
                                if isLoggedToday(meal.label) && justLogged != meal.label {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                        .offset(x: 12, y: -8)
                                }
                            }
                            Text(meal.label)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(active ? .white : Color.black.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(active ? meal.color : meal.color.opacity(0.7))
                        )
                        .scaleEffect(justLogged == meal.label ? 0.92 : 1.0)
                        .animation(.spring(response: 0.25), value: justLogged)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)

            if let msg = confirmMsg {
                Text(msg)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(wGreen)
                    .transition(.opacity)
            }
        }
        .padding(.bottom, 6)
    }

    private func log(_ meal: MealOption) {
        withAnimation(.spring(response: 0.2)) { justLogged = meal.label }
        let entry = WatchMealLog(date: Date(), mood: meal.mood, mealName: meal.label)
        context.insert(entry)
        try? context.save()
        WatchSyncManager.shared.sendMealToPhone(mealName: meal.label, mood: meal.mood.rawValue)
        withAnimation { confirmMsg = "\(meal.label) logged ✓" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                justLogged = nil
                confirmMsg = nil
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 3. Streak View
// ─────────────────────────────────────────────────────────────────────────────

struct WatchStreakView: View {
    @Query(sort: \WatchMealLog.date, order: .reverse) private var logs: [WatchMealLog]
    @State private var glow = false

    private var streak: Int {
        var count = 0
        var day = Calendar.current.startOfDay(for: Date())
        while logs.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: day) }) {
            count += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return count
    }

    private var streakMessage: String {
        switch streak {
        case 0:     return "Log a meal to start!"
        case 1:     return "You're on fire!"
        case 2...4: return "Keep the streak going!"
        case 5...7: return "What a week!"
        default:    return "Unstoppable!"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            WatchHeader(title: "Streak")
            Text(streakMessage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            ZStack {
                Circle()
                    .fill(wOrange.opacity(0.15))
                    .frame(width: 70, height: 70)
                    .scaleEffect(glow ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: glow)
                Image(systemName: "flame.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(
                        LinearGradient(colors: [wYellow, wOrange], startPoint: .top, endPoint: .bottom)
                    )
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(max(streak, 1))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(wOrange)
                Text(streak == 1 ? "day" : "days in a row")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.bottom, 8)
        .onAppear { glow = true }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 4. Analytics View
// ─────────────────────────────────────────────────────────────────────────────

struct WatchAnalyticsView: View {
    @Query(sort: \WatchMealLog.date, order: .reverse) private var logs: [WatchMealLog]

    private var todayCount: Int {
        logs.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    private var weekTotal: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -6,
            to: Calendar.current.startOfDay(for: Date())) ?? Date()
        return logs.filter { $0.date >= weekAgo }.count
    }

    private let dayLabels  = ["S","M","T","W","T","F","S"]
    private let barColors: [Color] = [wGreen, wPink, wOrange, wYellow, wOrange, wGreen, wPink]

    private var last7: [Int] {
        (0..<7).reversed().map { (offset: Int) -> Int in
            guard let day = Calendar.current.date(
                byAdding: .day, value: -offset,
                to: Calendar.current.startOfDay(for: Date()))
            else { return 0 }
            return logs.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }.count
        }
    }

    private let mealIcons: [(symbol: String, label: String, color: Color)] = [
        ("sun.horizon.fill",                  "Breakfast", wYellow),
        ("fork.knife",                        "Lunch",     wGreen),
        ("moon.stars.fill",                   "Dinner",    wOrange),
        ("takeoutbag.and.cup.and.straw.fill", "Snack",     wPink),
    ]

    var body: some View {
        TabView {
            todayPage
            weekPage
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var todayPage: some View {
        VStack(spacing: 4) {
            WatchHeader(title: "Analytics")
            Text("Today")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(todayCount)")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(todayCount >= defaultGoal ? wOrange : wGreen)
                Text("/ \(defaultGoal)")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
            Text("Meals logged")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
            HStack(spacing: 4) {
                ForEach(mealIcons, id: \.label) { item in
                    let loggedToday = logs.contains {
                        $0.mealName == item.label && Calendar.current.isDateInToday($0.date)
                    }
                    VStack(spacing: 2) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 14))
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(loggedToday ? item.color : item.color.opacity(0.3))
                            )
                            .foregroundColor(loggedToday ? .white : item.color)
                        Text(item.label)
                            .font(.system(size: 6))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding(.bottom, 6)
    }

    private var weekPage: some View {
        VStack(spacing: 4) {
            WatchHeader(title: "Analytics")
            Text("This week")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(last7.enumerated()), id: \.0) { i, count in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColors[i % barColors.count])
                            .frame(width: 16, height: max(CGFloat(count) * 12 + 6, 6))
                        Text(dayLabels[i % 7])
                            .font(.system(size: 7))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(height: 55, alignment: .bottom)
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Total Meals")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(weekTotal) / \(defaultGoal * 7)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 6)
        }
        .padding(.bottom, 6)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Previews
// ─────────────────────────────────────────────────────────────────────────────

#Preview("State")     { WatchStateView() }
#Preview("Log Food")  { WatchLogFoodView() }
#Preview("Streak")    { WatchStreakView() }
#Preview("Analytics") { WatchAnalyticsView() }
