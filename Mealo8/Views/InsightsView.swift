import SwiftUI
import SwiftData

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Design tokens
// ─────────────────────────────────────────────────────────────────────────────

private enum MT {
    static let bg         = Color("background")
    static let card       = Color("CardsColor")
    static let accent     = Color("orange")
    static let accentSoft = Color("pink")
    static let text       = Color("brown")
    static let muted      = Color("brown").opacity(0.5)
    static let border     = Color("pink")
    static let tabOff     = Color("brown").opacity(0.4)

    static let xs: CGFloat =  4
    static let sm: CGFloat =  8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - InsightsView
// ─────────────────────────────────────────────────────────────────────────────

struct InsightsView: View {

    @Query(sort: \MealLog.date, order: .reverse) private var logs: [MealLog]
    @Query private var profiles: [UserProfile]

    // FIX: no args needed — init has defaults now
    @StateObject private var vm = InsightsViewModel()
    @Environment(\.dismiss) private var dismiss

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            MT.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: MT.lg) {
                    topNavSection
                    patternCard
                    calendarSection
                    insightsCard
                    goalCard
                    Spacer(minLength: MT.xl)
                }
                .padding(.top, MT.md)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: logs)     { _, newLogs     in vm.update(logs: newLogs,  profile: profile) }
        .onChange(of: profiles) { _, newProfiles in vm.update(logs: logs,     profile: newProfiles.first) }
        .onAppear               {                   vm.update(logs: logs,     profile: profile) }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: 1 — Top navigation
    // ─────────────────────────────────────────────────────────────

    private var topNavSection: some View {
        VStack(spacing: MT.md) {

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(MT.text)
                        .padding(MT.sm)
                        .background(
                            Circle().fill(MT.card)
                                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                        )
                }
                Spacer()
            }
            .padding(.horizontal, MT.md)

            HStack(spacing: 0) {
                ForEach(Timeframe.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            vm.select(timeframe: tab, logs: logs, profile: profile)
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 15,
                                          weight: vm.selectedTimeframe == tab ? .semibold : .regular))
                            .foregroundColor(vm.selectedTimeframe == tab ? .white : MT.tabOff)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Group {
                                    if vm.selectedTimeframe == tab {
                                        Capsule().fill(MT.accent)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Capsule().fill(MT.card))
            .overlay(Capsule().stroke(MT.border, lineWidth: 1))
            .padding(.horizontal, MT.md)

            HStack {
                Button { vm.navigateBack(logs: logs, profile: profile) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(vm.canGoBack ? MT.text : MT.border)
                }
                .disabled(!vm.canGoBack)

                Spacer()

                Text(vm.periodLabel)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MT.text)

                Spacer()

                Button { vm.navigateForward(logs: logs, profile: profile) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(vm.canGoForward ? MT.text : MT.border)
                }
                .disabled(!vm.canGoForward)
            }
            .padding(.horizontal, MT.xl)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: 2 — Pattern card
    // ─────────────────────────────────────────────────────────────

    private var patternCard: some View {
        HStack(alignment: .top, spacing: MT.md) {
            Image("ch1")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            VStack(alignment: .leading, spacing: MT.sm) {
                Text("Your energy pattern")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MT.accent)
                    .italic()

                Text(vm.periodData?.patternHeadline ?? "Log meals to see your pattern.")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(MT.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(vm.periodData?.patternSubtext ?? "Your rhythm will appear here once you start logging.")
                    .font(.system(size: 13))
                    .foregroundColor(MT.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(MT.lg)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(MT.card))
        .padding(.horizontal, MT.md)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: 3 — Calendar (week + month only)
    // ─────────────────────────────────────────────────────────────

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: MT.md) {

            HStack {
                Text("Calendar")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(MT.text)
                Spacer()
                moodLegend
            }

            HStack(spacing: 0) {
                ForEach(["mon","tue","wed","thu","fri","sat","sun"], id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(MT.muted)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 6
            ) {
                ForEach(Array(vm.calendarGrid.enumerated()), id: \.offset) { _, optDate in
                    if let date = optDate {
                        CalendarDayCell(
                            date:      date,
                            mood:      vm.mood(for: date),
                            isEnabled: vm.isEnabled(date),
                            isToday:   MealoDate.isSameDay(date, Date())
                        )
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .padding(MT.lg)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(MT.card))
        .padding(.horizontal, MT.md)
    }

    private var moodLegend: some View {
        HStack(spacing: 6) {
            ForEach(MoodState.allCases, id: \.self) { mood in
                HStack(spacing: 3) {
                    Circle().fill(mood.color).frame(width: 7, height: 7)
                    Text(mood.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(MT.muted)
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: 4 — Personal insights
    // ─────────────────────────────────────────────────────────────

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("personal insights")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(MT.text)
                .padding(.bottom, MT.md)

            let items = vm.periodData?.insights ?? [
                Insight(icon: "✨", text: "Start logging meals to unlock your personal insights.")
            ]

            ForEach(Array(items.enumerated()), id: \.element.id) { idx, insight in
                HStack(alignment: .top, spacing: MT.md) {
                    Text(insight.icon)
                        .font(.system(size: 20))
                        .frame(width: 28)

                    Text(insight.text)
                        .font(.system(size: 14))
                        .foregroundColor(MT.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(.vertical, MT.xs)

                if idx < items.count - 1 {
                    Divider().background(MT.border).padding(.vertical, MT.xs)
                }
            }
        }
        .padding(MT.lg)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(MT.card))
        .padding(.horizontal, MT.md)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: 5 — Goal progress
    // ─────────────────────────────────────────────────────────────

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: MT.lg) {
            Text("Progress to your goal")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(MT.text)

            HStack(spacing: MT.lg) {
                VStack(spacing: MT.xs) {
                    Image("ch1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)

                    let pct = Int((vm.periodData?.goalProgress ?? 0) * 100)
                    Text("\(pct)%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MT.muted)
                }

                VStack(alignment: .leading, spacing: MT.sm) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(MT.accentSoft.opacity(0.35))
                                .frame(height: 26)
                            Capsule()
                                .fill(MT.accent)
                                .frame(
                                    width: geo.size.width * CGFloat(vm.periodData?.goalProgress ?? 0),
                                    height: 26
                                )
                                .animation(.spring(response: 0.8, dampingFraction: 0.7),
                                           value: vm.periodData?.goalProgress)
                        }
                    }
                    .frame(height: 26)

                    Text(vm.periodData?.goalProgressText ?? "Start logging today to build your rhythm.")
                        .font(.system(size: 13))
                        .foregroundColor(MT.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(MT.lg)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(MT.card))
        .padding(.horizontal, MT.md)
    }

}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - CalendarDayCell
// ─────────────────────────────────────────────────────────────────────────────

private struct CalendarDayCell: View {
    let date:      Date
    let mood:      MoodState?
    let isEnabled: Bool
    let isToday:   Bool

    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        f.calendar   = MealoDate.calendar
        f.timeZone   = .current
        return f.string(from: date)
    }

    var body: some View {
        ZStack {
            // Circle ONLY for days that have a logged mood
            if let mood {
                Circle()
                    .strokeBorder(mood.color, lineWidth: 1.8)
                    .background(Circle().fill(mood.color.opacity(0.08)))
            }
            // Today with no log: subtle orange ring
            else if isToday && isEnabled {
                Circle()
                    .strokeBorder(Color("orange").opacity(0.35), lineWidth: 1.2)
            }
            // All other days: no circle whatsoever

            Text(dayNumber)
                .font(.system(size: 13, weight: mood != nil ? .semibold : .regular))
                .foregroundColor(
                    !isEnabled  ? Color("pink")
                  : mood != nil ? mood!.color
                  : isToday     ? Color("orange")
                                : Color("brown").opacity(0.55)
                )
        }
        .frame(width: 36, height: 36)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview (fixed sample days — not random)
// ─────────────────────────────────────────────────────────────────────────────

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MealLog.self, UserProfile.self,
                                        configurations: config)
    let ctx = container.mainContext

    let signup = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    ctx.insert(UserProfile(name: "Rahaf", signupDate: signup, dailyMealGoal: 3))

    // Fixed days — same result every preview render
    let sampleDays:  [Int]        = [-1, -2, -3, -5, -7, -8, -10, -14, -15, -20]
    let sampleMoods: [MoodState]  = [.happy, .excited, .tired, .happy, .sad,
                                     .excited, .happy, .tired, .happy, .excited]
    let sampleHours: [Int]        = [8, 12, 13, 18, 19, 8, 12, 13, 18, 19]

    for i in sampleDays.indices {
        guard let day  = Calendar.current.date(byAdding: .day, value: sampleDays[i], to: Date()),
              let time = Calendar.current.date(bySettingHour: sampleHours[i],
                                               minute: 30, second: 0, of: day)
        else { continue }
        ctx.insert(MealLog(date: time, mood: sampleMoods[i]))
    }

    return NavigationStack { InsightsView() }
        .modelContainer(container)
}
