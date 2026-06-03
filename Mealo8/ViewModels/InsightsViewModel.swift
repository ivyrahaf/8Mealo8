//
//  InisghtsViewModel.swift
//  Mealo
//
//  Created by Rahaf on 31/05/2026.

//  1. init() has default parameters so InsightsView can use @StateObject normally
//  2. select(timeframe:) resets anchorDate to today
//  3. isEnabled() also checks isNotFuture
//  4. updateNavigationGuards() correctly handles month boundary
//

import SwiftData
import SwiftUI
import Combine

@MainActor
final class InsightsViewModel: ObservableObject {

    // ─────────────────────────────────────────────────────────────
    // MARK: Published state
    // ─────────────────────────────────────────────────────────────

    @Published var selectedTimeframe: Timeframe = .month
    @Published var anchorDate: Date = Date()

    @Published private(set) var periodLabel:  String             = ""
    @Published private(set) var calendarGrid: [Date?]            = []
    @Published private(set) var periodData:   InsightsPeriodData?
    @Published private(set) var canGoBack:    Bool               = false
    @Published private(set) var canGoForward: Bool               = false

    // ─────────────────────────────────────────────────────────────
    // MARK: Private data
    // ─────────────────────────────────────────────────────────────

    private var logs:    [MealLog]
    private var profile: UserProfile?

    // ─────────────────────────────────────────────────────────────
    // MARK: Init — default params so @StateObject works without args
    // ─────────────────────────────────────────────────────────────

    init(logs: [MealLog] = [], profile: UserProfile? = nil) {
        self.logs    = logs
        self.profile = profile
        refresh()
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Called from view when SwiftData delivers new data
    // ─────────────────────────────────────────────────────────────

    func update(logs: [MealLog], profile: UserProfile?) {
        self.logs    = logs
        self.profile = profile
        refresh()
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Actions — always pass fresh logs+profile from the view
    // ─────────────────────────────────────────────────────────────

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

    // ─────────────────────────────────────────────────────────────
    // MARK: Calendar helpers
    // ─────────────────────────────────────────────────────────────

    func mood(for date: Date) -> MoodState? {
        periodData?.daySummaries.first { MealoDate.isSameDay($0.date, date) }?.mood
    }

    // FIX: also checks isNotFuture so future days are always greyed out
    func isEnabled(_ date: Date) -> Bool {
        guard let profile else { return false }
        return MealoDate.isOnOrAfter(date, signupDate: profile.signupDate) &&
               MealoDate.isNotFuture(date)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Private refresh
    // ─────────────────────────────────────────────────────────────

    private func refresh() {
        periodLabel  = MealoDate.periodLabel(for: anchorDate, timeframe: selectedTimeframe)
        calendarGrid = InsightsRepository.calendarGrid(anchor: anchorDate, timeframe: selectedTimeframe)

        if let profile {
            periodData = InsightsRepository.periodData(
                logs:      logs,
                profile:   profile,
                anchor:    anchorDate,
                timeframe: selectedTimeframe
            )
        } else {
            periodData = nil
        }

        updateNavigationGuards()
    }

    private func updateNavigationGuards() {
        guard let profile else {
            canGoBack    = false
            canGoForward = false
            return
        }

        let prevAnchor = MealoDate.navigate(anchorDate, timeframe: selectedTimeframe, forward: false)
        switch selectedTimeframe {
        case .week:
            let (start, _) = MealoDate.weekBounds(for: prevAnchor)
            canGoBack = MealoDate.isOnOrAfter(start, signupDate: profile.signupDate)
        case .month:
            let monthStart = MealoDate.calendar.date(
                from: MealoDate.calendar.dateComponents([.year, .month], from: prevAnchor)
            ) ?? prevAnchor
            canGoBack = MealoDate.isOnOrAfter(monthStart, signupDate: profile.signupDate)
        }

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
