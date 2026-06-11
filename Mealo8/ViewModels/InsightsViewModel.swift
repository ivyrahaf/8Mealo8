import SwiftData
import SwiftUI
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {

    @Published var selectedTimeframe: Timeframe = .month
    @Published var anchorDate: Date = Date()

    @Published private(set) var periodLabel:  String             = ""
    @Published private(set) var calendarGrid: [Date?]            = []
    @Published private(set) var periodData:   InsightsPeriodData?
    @Published private(set) var canGoBack:    Bool               = false
    @Published private(set) var canGoForward: Bool               = false

    private var logs:    [MealLog]
    private var profile: UserProfile?

    init(logs: [MealLog] = [], profile: UserProfile? = nil) {
        self.logs    = logs
        self.profile = profile
        refresh()
    }

    func update(logs: [MealLog], profile: UserProfile?) {
        self.logs    = logs
        self.profile = profile
        refresh()
    }

    func select(timeframe: Timeframe, logs: [MealLog], profile: UserProfile?) {
        self.logs         = logs
        self.profile      = profile
        selectedTimeframe = timeframe
        anchorDate        = Date()
        refresh()
    }

    func navigateBack(logs: [MealLog], profile: UserProfile?) {
        guard canGoBack else { return }
        self.logs    = logs
        self.profile = profile
        anchorDate = MealoDate.navigate(anchorDate, timeframe: selectedTimeframe, forward: false)
        refresh()
    }

    func navigateForward(logs: [MealLog], profile: UserProfile?) {
        guard canGoForward else { return }
        self.logs    = logs
        self.profile = profile
        anchorDate = MealoDate.navigate(anchorDate, timeframe: selectedTimeframe, forward: true)
        refresh()
    }

    func mood(for date: Date) -> MoodState? {
        periodData?.daySummaries.first { MealoDate.isSameDay($0.date, date) }?.mood
    }

    func isEnabled(_ date: Date) -> Bool {
        let signupDate = profile?.signupDate ?? logs.map(\.date).min() ?? Date()
        return MealoDate.calendar.startOfDay(for: date) >= MealoDate.calendar.startOfDay(for: signupDate) &&
               MealoDate.isNotFuture(date)
    }

    private func refresh() {
        periodLabel  = MealoDate.periodLabel(for: anchorDate, timeframe: selectedTimeframe)
        calendarGrid = InsightsRepository.calendarGrid(anchor: anchorDate, timeframe: selectedTimeframe)

        // Use real profile or create a default so insights always work
        let activeProfile = profile ?? UserProfile(
            name: "Friend",
            signupDate: logs.map(\.date).min() ?? Date(),
            dailyMealGoal: 3
        )
        periodData = InsightsRepository.periodData(
            logs:      logs,
            profile:   activeProfile,
            anchor:    anchorDate,
            timeframe: selectedTimeframe
        )

        updateNavigationGuards()
    }

    private func updateNavigationGuards() {
        let signupDate = profile?.signupDate ?? logs.map(\.date).min() ?? Date()

        // ── Can go back? Only to signup month, not before ──
        let prevAnchor = MealoDate.navigate(anchorDate, timeframe: selectedTimeframe, forward: false)
        switch selectedTimeframe {
        case .week:
            let (start, _) = MealoDate.weekBounds(for: prevAnchor)
            canGoBack = MealoDate.isOnOrAfter(start, signupDate: signupDate)
        case .month:
            let monthStart = MealoDate.calendar.date(
                from: MealoDate.calendar.dateComponents([.year, .month], from: prevAnchor)
            ) ?? prevAnchor
            canGoBack = MealoDate.isOnOrAfter(monthStart, signupDate: signupDate)
        }

        // ── Can go forward? Up to current month/week, not future ──
        let nextAnchor = MealoDate.navigate(anchorDate, timeframe: selectedTimeframe, forward: true)
        switch selectedTimeframe {
        case .week:
            let (start, _) = MealoDate.weekBounds(for: nextAnchor)
            canGoForward = MealoDate.isNotFuture(start)
        case .month:
            let monthStart = MealoDate.calendar.date(
                from: MealoDate.calendar.dateComponents([.year, .month], from: nextAnchor)
            ) ?? nextAnchor
            canGoForward = MealoDate.isNotFuture(monthStart)
        }
    }
}
