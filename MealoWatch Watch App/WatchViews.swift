//
//  WatchViews.swift
//  Mealo Watch App Watch App
//

import SwiftUI
import SwiftData

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Models
// ─────────────────────────────────────────────────────────────────────────────
// Note: These should ideally be in a shared framework/target between your
// main app and Watch app. If they already exist elsewhere, make sure
// this file's target membership includes access to them.

enum MoodState: String, Codable {
    case happy
    case excited
    case neutral
    case sad
}

@Model
final class MealLog {
    var date: Date
    var mood: MoodState
    var note: String
    
    init(date: Date, mood: MoodState, note: String) {
        self.date = date
        self.mood = mood
        self.note = note
    }
}

@Model
final class UserProfile {
    var dailyMealGoal: Int
    
    init(dailyMealGoal: Int = 4) {
        self.dailyMealGoal = dailyMealGoal
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Colors
// ─────────────────────────────────────────────────────────────────────────────

private let wOrange = Color(red: 0.91, green: 0.45, blue: 0.32)
private let wGreen  = Color(red: 0.55, green: 0.72, blue: 0.55)
private let wYellow = Color(red: 0.97, green: 0.85, blue: 0.45)
private let wPink   = Color(red: 0.98, green: 0.82, blue: 0.82)
private let wBg     = Color.black

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Shared header
// ─────────────────────────────────────────────────────────────────────────────

private struct WatchHeader: View {
    let title: String
    var body: some View {
        HStack {
            Image("ch1")
                .resizable().scaledToFit()
                .frame(width: 28, height: 28)
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
// MARK: - 1. State View
// ─────────────────────────────────────────────────────────────────────────────

struct WatchStateView: View {
    @State private var bounce = false

    var body: some View {
        VStack(spacing: 6) {
            WatchHeader(title: "State")

            Image("ch1")
                .resizable().scaledToFit()
                .frame(width: 100, height: 100)
                .offset(y: bounce ? -8 : 0)
                .animation(
                    .interpolatingSpring(stiffness: 130, damping: 6)
                    .repeatForever(autoreverses: true),
                    value: bounce
                )

            Text("You're doing great!")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Keep it up! 🤍")
                .font(.system(size: 11))
                .foregroundColor(wOrange)
        }
        .padding(.bottom, 8)
        .onAppear { bounce = true }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 2. Log Food View
// ─────────────────────────────────────────────────────────────────────────────

struct WatchLogFoodView: View {
    @Environment(\.modelContext) private var context

    private struct MealOption {
        let label:  String
        let symbol: String
        let color:  Color
        let mood:   MoodState
    }

    private let options: [MealOption] = [
        MealOption(label: "Breakfast", symbol: "sun.horizon.fill",    color: wYellow, mood: .happy),
        MealOption(label: "Lunch",     symbol: "fork.knife",          color: wGreen,  mood: .excited),
        MealOption(label: "Dinner",    symbol: "moon.stars.fill",     color: wOrange, mood: .happy),
        MealOption(label: "Snack",     symbol: "takeoutbag.and.cup.and.straw.fill", color: wPink, mood: .excited),
    ]

    @State private var logged: Set<String> = []
    @State private var saved:  String?     = nil

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
                ForEach(options, id: \.label) { meal in
                    Button {
                        log(meal)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: meal.symbol)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(logged.contains(meal.label) ? .white : .black.opacity(0.7))
                            Text(meal.label)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(logged.contains(meal.label) ? .white : .black.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(logged.contains(meal.label) ? meal.color : meal.color.opacity(0.7))
                        )
                        .scaleEffect(logged.contains(meal.label) ? 0.94 : 1.0)
                        .animation(.spring(response: 0.25), value: logged.contains(meal.label))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)

            if let s = saved {
                Text("\(s) logged! ✓")
                    .font(.system(size: 10))
                    .foregroundColor(wGreen)
                    .transition(.opacity)
            }
        }
        .padding(.bottom, 6)
    }

    private func log(_ meal: MealOption) {
        withAnimation { logged.insert(meal.label) }
        let entry = MealLog(date: Date(), mood: meal.mood, note: meal.label)
        context.insert(entry)
        try? context.save()
        withAnimation { saved = meal.label }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { saved = nil }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - 3. Streak View
// ─────────────────────────────────────────────────────────────────────────────

struct WatchStreakView: View {
    @Query(sort: \MealLog.date, order: .reverse) private var logs: [MealLog]
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

    var body: some View {
        VStack(spacing: 6) {
            WatchHeader(title: "Streak")

            Text("You're on fire!")
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
                Text("days in a row")
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
    @Query(sort: \MealLog.date, order: .reverse) private var logs: [MealLog]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    private var todayCount: Int {
        logs.filter { Calendar.current.isDateInToday($0.date) }.count
    }

    private var dailyGoal: Int { profile?.dailyMealGoal ?? 4 }

    private let dayLabels = ["S","M","T","W","T","F","S"]
    private let barColors: [Color] = [wGreen, wPink, wOrange, wYellow, wOrange, wGreen, wPink]

    private var last7: [Int] {
        (0..<7).reversed().map { offset -> Int in
            guard let day = Calendar.current.date(byAdding: .day, value: -offset, to: Calendar.current.startOfDay(for: Date()))
            else { return 0 }
            return logs.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }.count
        }
    }

    private var meals: [(String, String, Color)] = [
        ("sun.horizon.fill", "Breakfast", wYellow),
        ("fork.knife",       "Lunch",     wGreen),
        ("moon.stars.fill",  "Dinner",    wOrange),
        ("takeoutbag.and.cup.and.straw.fill", "Snack", wPink),
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
                    .foregroundColor(todayCount >= dailyGoal ? wOrange : wGreen)
                Text("/ \(dailyGoal)")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }

            Text("Meals logged")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 4) {
                ForEach(meals, id: \.1) { symbol, label, color in
                    VStack(spacing: 2) {
                        Image(systemName: symbol)
                            .font(.system(size: 14))
                            .frame(width: 28, height: 28)
                            .background(RoundedRectangle(cornerRadius: 7).fill(color.opacity(0.3)))
                            .foregroundColor(color)
                        Text(label)
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
                    Text("\(logs.count) / \(dailyGoal * 7)")
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
