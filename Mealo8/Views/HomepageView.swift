//
//  HomepageView.swift
//  Mealo
//

import SwiftUI
import SwiftData

struct HomepageView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \MealLog.date, order: .reverse) private var logs: [MealLog]
    @Query private var profiles: [UserProfile]

    @State private var justLogged: String? = nil
    @State private var confirmMsg: String? = nil

    private var profile: UserProfile? { profiles.first }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<21: return "Good evening,"
        default:      return "Good night,"
        }
    }

    private var streak: Int {
        var count = 0
        var day = MealoDate.calendar.startOfDay(for: Date())
        while logs.contains(where: { MealoDate.isSameDay($0.date, day) }) {
            count += 1
            day = MealoDate.calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return count
    }

    // ── Quick log options ───────────────────────────────────────────

    private struct QuickLogOption: Identifiable {
        let id = UUID()
        let icon:   String
        let label:  String
        let symbol: String
        let color:  Color
        let mood:   MoodState
    }

    private let quickOptions: [QuickLogOption] = [
        QuickLogOption(icon: "sun.horizon.fill", label: "Breakfast",  symbol: "sun.horizon.fill",                  color: Color(red: 0.97, green: 0.85, blue: 0.45), mood: .happy),
        QuickLogOption(icon: "fork.knife",       label: "Lunch",      symbol: "fork.knife",                        color: Color(red: 0.55, green: 0.72, blue: 0.55), mood: .excited),
        QuickLogOption(icon: "moon.stars.fill",   label: "Dinner",    symbol: "moon.stars.fill",                   color: Color(red: 0.91, green: 0.45, blue: 0.32), mood: .happy),
        QuickLogOption(icon: "takeoutbag.and.cup.and.straw.fill", label: "Snack", symbol: "takeoutbag.and.cup.and.straw.fill", color: Color(red: 0.98, green: 0.82, blue: 0.82), mood: .excited),
    ]

    private func isLoggedToday(_ label: String) -> Bool {
        logs.contains { $0.note == label && Calendar.current.isDateInToday($0.date) }
    }

    private func logMeal(_ option: QuickLogOption) {
        withAnimation(.spring(response: 0.25)) { justLogged = option.label }

        let entry = MealLog(date: Date(), mood: option.mood, note: option.label)
        context.insert(entry)
        try? context.save()

        withAnimation { confirmMsg = "\(option.label) logged ✓" }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                justLogged = nil
                confirmMsg = nil
            }
        }
    }

    // ── Week data ───────────────────────────────────────────────────

    private var last7Days: [DayBarData] {
        (0..<7).reversed().compactMap { offset -> DayBarData? in
            guard let day = MealoDate.calendar.date(
                byAdding: .day, value: -offset,
                to: MealoDate.calendar.startOfDay(for: Date())
            ) else { return nil }
            let dayLogs = logs.filter { MealoDate.isSameDay($0.date, day) }
            let mood    = Dictionary(grouping: dayLogs, by: { $0.mood })
                .max(by: { $0.value.count < $1.value.count })?.key
            let label   = MealoDate.formatted(day, format: "EEE")
            return DayBarData(label: label, mood: mood, logCount: dayLogs.count)
        }
    }

    private var thisWeekLogs: [MealLog] {
        guard let ago = MealoDate.calendar.date(
            byAdding: .day, value: -6,
            to: MealoDate.calendar.startOfDay(for: Date())
        ) else { return [] }
        return logs.filter { $0.date >= ago }
    }

    private var weekAvgHour: Int? {
        let h = thisWeekLogs.map { MealoDate.calendar.component(.hour, from: $0.date) }
        return h.isEmpty ? nil : h.reduce(0, +) / h.count
    }

    private var weekHeadline: String {
        guard let avg = weekAvgHour else { return "Start logging to see\nyour pattern." }
        switch avg {
        case 5..<11:  return "You nourished yourself\nmore in the mornings."
        case 11..<15: return "You nourished yourself\nmore during slower\nafternoons."
        case 15..<19: return "You nourished yourself\nmost in the afternoons."
        default:      return "You nourished yourself\nmore in the evenings."
        }
    }

    private var weekSubtext: String {
        guard let avg = weekAvgHour else { return "" }
        switch avg {
        case 5..<11:  return "Mornings were your\nstrongest windows."
        case 11..<15: return "Afternoons were your\nstrongest windows."
        case 15..<19: return "Late afternoons were\nyour strongest windows."
        default:      return "Evenings were your\nstrongest windows."
        }
    }

    // ── Body ────────────────────────────────────────────────────────

    var body: some View {
        NavigationStack {
            ZStack {
                Color("background").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        headerSection
                        heroCard
                        quickLogCard
                        insightCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // ── Header ──────────────────────────────────────────────────────

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.custom("Georgia", size: 22)).bold()
                    .foregroundColor(Color("brown"))
                Text(profile?.name ?? "Friend")
                    .font(.custom("Georgia", size: 22)).bold()
                    .foregroundColor(Color("brown"))
            }
            Spacer()
            HStack(spacing: 16) {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("orange"))
                    if streak > 0 {
                        Text("\(streak)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("orange"))
                    }
                }
                NavigationLink(destination: InsightsView()) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color("orange"))
                }
            }
        }
    }

    // ── Hero card ────────────────────────────────────────────────────

    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color("orange").opacity(0.45), Color("orange").opacity(0.8)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(height: 210)
            Image("ch1")
                .resizable().scaledToFit()
                .frame(height: 190)
        }
    }

    // ── Quick log card (inline — no sheet) ───────────────────────────

    private var quickLogCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Log a meal")
                    .font(.custom("Georgia", size: 20)).bold()
                    .foregroundColor(Color("brown"))
                Spacer()
                if let msg = confirmMsg {
                    Text(msg)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color("green"))
                        .transition(.opacity)
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(quickOptions) { option in
                    let logged = isLoggedToday(option.label)
                    let flashing = justLogged == option.label

                    Button { logMeal(option) } label: {
                        HStack(spacing: 10) {
                            Image(systemName: option.icon)
                                .font(.system(size: 20))
                                .foregroundColor(logged || flashing ? .white : option.color)
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(logged || flashing ? option.color : option.color.opacity(0.2))
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.label)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color("brown"))
                                if logged {
                                    Text("Logged ✓")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color("green"))
                                }
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color("background"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(logged ? option.color.opacity(0.5) : Color("pink").opacity(0.3), lineWidth: 1.5)
                                )
                        )
                        .scaleEffect(flashing ? 0.95 : 1.0)
                        .animation(.spring(response: 0.25), value: flashing)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(Color("CardsColor"))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // ── Insight card ─────────────────────────────────────────────────

    private var insightCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This week's\nrhythm")
                        .font(.custom("Georgia", size: 16)).bold()
                        .foregroundColor(Color("brown"))
                    Text(weekHeadline)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color("brown"))
                    Text(weekSubtext)
                        .font(.system(size: 11))
                        .foregroundColor(Color("orange"))
                }
                .frame(width: 105, alignment: .leading)

                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(last7Days) { day in
                        VStack(spacing: 5) {
                            WeekBarView(day: day)
                            Text(day.label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color("brown").opacity(0.55))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(18)

            NavigationLink(destination: InsightsView()) {
                Text("View deeper insights")
                    .font(.custom("Georgia", size: 16)).bold()
                    .foregroundColor(Color("brown"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color("orange").opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(Color("CardsColor"))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DayBarData
// ─────────────────────────────────────────────────────────────────────────────

struct DayBarData: Identifiable {
    let id       = UUID()
    let label:   String
    let mood:    MoodState?
    let logCount: Int
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - WeekBarView
// ─────────────────────────────────────────────────────────────────────────────

struct WeekBarView: View {
    let day: DayBarData

    private let trackH:  CGFloat = 100
    private let minFill: CGFloat = 22
    private let maxFill: CGFloat = 80

    private var fillH: CGFloat {
        guard day.logCount > 0 else { return minFill }
        return min(minFill + CGFloat(day.logCount) * 20, maxFill)
    }

    private var color: Color {
        day.mood?.color ?? Color("button")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(color.opacity(0.18))
                .frame(width: 30, height: trackH)
            Capsule()
                .fill(color)
                .frame(width: 30, height: fillH)
        }
    }
}
