import SwiftUI
import SwiftData

// MARK: - Homepage View

struct HomepageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MealLog.date, order: .reverse) private var mealLogs: [MealLog]
    @AppStorage("userName") private var userName: String = "Friend"
    @State private var showStreakSheet = false
    @State private var justLogged: QuickLogSlot? = nil
    @State private var confirmMsg: String? = nil

    private var streakCount: Int {
        let calendar   = Calendar.current
        let today      = calendar.startOfDay(for: Date())
        let loggedDays = Set(mealLogs.map { calendar.startOfDay(for: $0.date) })
        var cursor = loggedDays.contains(today)
            ? today
            : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)
        var count = 0
        while loggedDays.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            if count > 365 { break }
            cursor = prev
        }
        return count
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default:      return "Good evening,"
        }
    }

    private var characterMood: CharacterMood {
        let todayLogs = mealLogs.filter { Calendar.current.isDateInToday($0.date) }
        switch todayLogs.count {
        case 3...: return .happy
        case 2:    return .okay
        case 1:    return .tired
        default:   return .sad
        }
    }

    private func logMeal(_ slot: QuickLogSlot) {
        // Flash button
        withAnimation(.spring(response: 0.25)) { justLogged = slot }

        // Save to SwiftData
        let entry = MealLog(date: Date(), mood: slot.defaultMood, note: slot.mealName)
        modelContext.insert(entry)
        try? modelContext.save()
        WatchSyncManager.shared.sendMealToWatch(mealName: slot.mealName, mood: slot.defaultMood.rawValue)

        // Show confirmation
        withAnimation { confirmMsg = "\(slot.mealName) logged ✓" }

        // Reset everything after 1.5s — button goes back to normal
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                justLogged = nil
                confirmMsg = nil
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // ── Header ──────────────────────────────────────────
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(greeting)
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text(userName)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        HStack(spacing: 16) {
                            Button { showStreakSheet = true } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(Color("orange"))
                                    if streakCount > 0 {
                                        Text("\(streakCount)")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color("orange"))
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: InsightsView()) {
                                Image(systemName: "trophy")
                                    .font(.system(size: 20, weight: .regular))
                                    .foregroundStyle(Color.primary.opacity(0.40))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                    // ── Character Hero Card ──────────────────────────────
                    CharacterHeroCard(mood: characterMood)
                        .padding(.horizontal, 20)

                    // ── Quick Log Card ────────────────────────────────────
                    VStack(alignment: .center, spacing: 16) {
                        HStack {
                            Text("Quick log")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Spacer()
                            if let msg = confirmMsg {
                                Text(msg)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color("green"))
                                    .transition(.opacity)
                            }
                        }

                        HStack(spacing: 12) {
                            ForEach(QuickLogSlot.allCases, id: \.self) { slot in
                                let flashing = justLogged == slot

                                Button { logMeal(slot) } label: {
                                    VStack(spacing: 9) {
                                        Image(systemName: slot.icon)
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundStyle(flashing ? Color("orange") : slot.iconTint)

                                        Text(slot.label)
                                            .font(.system(size: 11, weight: .regular, design: .rounded))
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(Color.primary.opacity(0.55))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(flashing
                                                  ? Color("orange").opacity(0.18)
                                                  : Color("yellow").opacity(0.28))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(
                                                flashing ? Color("orange").opacity(0.55) : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                                    .scaleEffect(flashing ? 0.95 : 1.0)
                                    .animation(.spring(response: 0.25), value: flashing)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 22)
                    .padding(.horizontal, 20)
                    .background(Color("CardsColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 20)

                    // ── Personal Insight Card ────────────────────────────
                    NavigationLink(destination: InsightsView()) {
                        PersonalInsightCard(logs: mealLogs)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 36)
            }
            .background(Color("background"))
            .sheet(isPresented: $showStreakSheet) {
                StreakView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Character Hero Card

struct CharacterHeroCard: View {
    let mood: CharacterMood

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color("yellow"),               location: 0.0),
                            .init(color: Color("orange").opacity(0.55), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Image(mood.imageName)
                .resizable()
                .scaledToFit()
                .padding(28)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
}

// MARK: - Personal Insight Card

struct PersonalInsightCard: View {
    let logs: [MealLog]

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private struct DayBar {
        let color: Color
        let height: CGFloat
    }

    private var weekBars: [DayBar] {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: Date())
        var comps    = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        comps.weekday = 2
        let monday   = calendar.date(from: comps) ?? today

        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday)
            else { return DayBar(color: .gray.opacity(0.20), height: 18) }

            let dayLogs = logs.filter { calendar.startOfDay(for: $0.date) == day }
            let isFuture = day > today

            guard !dayLogs.isEmpty else {
                return DayBar(
                    color:  isFuture ? Color.gray.opacity(0.13) : Color.gray.opacity(0.28),
                    height: 18
                )
            }

            let dominant = Dictionary(grouping: dayLogs, by: { $0.mood })
                .max(by: { $0.value.count < $1.value.count })?.key ?? .happy
            let h = min(CGFloat(dayLogs.count) * 18 + 26, 80)
            return DayBar(color: dominant.color, height: h)
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Personal insight")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(weekBars.enumerated()), id: \.offset) { i, bar in
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(bar.color)
                                .frame(width: 22, height: bar.height)
                            Text(dayLabels[i])
                                .font(.system(size: 9, weight: .regular))
                                .foregroundStyle(Color.primary.opacity(0.45))
                        }
                    }
                }
            }
            Spacer(minLength: 10)
            Image("ch1")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .offset(y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color("CardsColor"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Supporting Enums

enum CharacterMood {
    case happy, okay, tired, sad

    var imageName: String {
        switch self {
        case .happy: return "ch1"
        case .okay:  return "ch2"
        case .tired: return "ch3"
        case .sad:   return "ch4"
        }
    }
}

enum QuickLogSlot: CaseIterable, Hashable {
    case morning, midday, evening

    var icon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .midday:  return "sun.min.fill"
        case .evening: return "moon"
        }
    }

    var label: String {
        switch self {
        case .morning: return "Morning\nmoment"
        case .midday:  return "Midday\nrefuel"
        case .evening: return "Evening\nwind down"
        }
    }

    var mealName: String {
        switch self {
        case .morning: return "Breakfast"
        case .midday:  return "Lunch"
        case .evening: return "Dinner"
        }
    }

    var defaultMood: MoodState {
        switch self {
        case .morning: return .happy
        case .midday:  return .excited
        case .evening: return .happy
        }
    }

    var iconTint: Color {
        switch self {
        case .morning: return Color("yellow")
        case .midday:  return Color("yellow").opacity(0.80)
        case .evening: return Color.indigo.opacity(0.65)
        }
    }
}

// MARK: - Preview

#Preview {
    HomepagePreview()
}

@MainActor
private struct HomepagePreview: View {
    private let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try! ModelContainer(for: MealLog.self, UserProfile.self, configurations: config)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekSeed: [(dayOffset: Int, mood: MoodState, hours: [Int])] = [
            (-2, .excited, [8, 13]),
            (-1, .happy,   [8, 13, 19]),
            ( 0, .happy,   [8, 13, 19]),
        ]
        for seed in weekSeed {
            for hour in seed.hours {
                guard let day  = cal.date(byAdding: .day, value: seed.dayOffset, to: today),
                      let time = cal.date(bySettingHour: hour, minute: 0, second: 0, of: day)
                else { continue }
                c.mainContext.insert(MealLog(date: time, mood: seed.mood))
            }
        }
        return c
    }()

    var body: some View {
        HomepageView()
            .modelContainer(container)
    }
}
