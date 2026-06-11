import SwiftUI
import SwiftData

// MARK: - Streak View

struct StreakView: View {
    @Query(sort: \MealLog.date, order: .reverse) private var mealLogs: [MealLog]

    private let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    // MARK: - Real streak: consecutive days ending today (or yesterday if today has no logs yet)
    private var streakDays: Int {
        let calendar   = Calendar.current
        let today      = calendar.startOfDay(for: Date())
        let loggedDays = Set(mealLogs.map { calendar.startOfDay(for: $0.date) })

        // Start from today; if today is empty, grace-period back to yesterday
        // so a streak isn't broken before the user has had a chance to log
        var cursor = loggedDays.contains(today)
            ? today
            : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)

        var count = 0
        while loggedDays.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            if count > 365 { break }   // safety cap
            cursor = prev
        }
        return count
    }

    // MARK: - Which days of the current Mon–Sun week have at least one log
    private var completedDays: [Bool] {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: Date())

        var comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        comps.weekday = 2 // Monday
        let monday = calendar.date(from: comps) ?? today

        let loggedDays = Set(mealLogs.map { calendar.startOfDay(for: $0.date) })

        return (0..<7).map { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { return false }
            return loggedDays.contains(day)
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // ── Title ────────────────────────────────────────────────
                Text("Streak")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                // ── Character ────────────────────────────────────────────
                Image("ch1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 196, height: 196)
                    .padding(.bottom, 28)

                // ── Main Card ────────────────────────────────────────────
                VStack(spacing: 0) {

                    // Day count
                    Text("\(streakDays) days")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .padding(.top, 28)
                        .padding(.bottom, 24)

                    // Week tracker row
                    WeekTrackerRow(
                        labels: weekdayLabels,
                        completed: completedDays
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 24)

                    Divider()
                        .padding(.horizontal, 20)

                    // Streak path section
                    StreakPathSection(streakDays: streakDays)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 28)
                }
                .background(Color("CardsColor"))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 4)
                .padding(.horizontal, 20)

            }
            .padding(.bottom, 40)
        }
        .background(Color("background"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Week Tracker Row

struct WeekTrackerRow: View {
    let labels: [String]
    let completed: [Bool]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
                VStack(spacing: 8) {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary.opacity(0.50))

                    ZStack {
                        // Track ring
                        Circle()
                            .strokeBorder(
                                completed[i]
                                    ? Color("orange").opacity(0.90)
                                    : Color.primary.opacity(0.18),
                                lineWidth: 1.8
                            )
                            .frame(width: 36, height: 36)

                        // Fill tint when complete
                        if completed[i] {
                            Circle()
                                .fill(Color("orange").opacity(0.12))
                                .frame(width: 36, height: 36)

                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color("orange"))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Streak Path Section

struct StreakPathSection: View {
    let streakDays: Int

    // 5 growth stages: seedling → tiny orange → small orange → big orange → happy orange
    private struct GrowthStage {
        let imageName: String   // nil means use SF symbol fallback
        let usesSystemImage: Bool
        let symbolName: String
        let targetSize: CGFloat
    }

    private let stages: [GrowthStage] = [
        GrowthStage(imageName: "",    usesSystemImage: true,  symbolName: "leaf.fill", targetSize: 28),
        GrowthStage(imageName: "ch4", usesSystemImage: false, symbolName: "",          targetSize: 46),
        GrowthStage(imageName: "ch3", usesSystemImage: false, symbolName: "",          targetSize: 60),
        GrowthStage(imageName: "ch2", usesSystemImage: false, symbolName: "",          targetSize: 72),
        GrowthStage(imageName: "ch1", usesSystemImage: false, symbolName: "",          targetSize: 88),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Label
            Text("Streak path")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("brown"))

            // Copy
            Text("Every day you show up,\nyour little Orange grows!")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color.primary.opacity(0.75))

            // Growth stages
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(stages.enumerated()), id: \.offset) { i, stage in
                    let isActive = i < streakDays

                    Group {
                        if stage.usesSystemImage {
                            Image(systemName: stage.symbolName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: stage.targetSize * 0.75, height: stage.targetSize * 0.75)
                                .foregroundStyle(isActive
                                    ? Color("green")
                                    : Color.gray.opacity(0.35))
                        } else {
                            Image(stage.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: stage.targetSize, height: stage.targetSize)
                                .opacity(isActive ? 1.0 : 0.28)
                                .grayscale(isActive ? 0.0 : 0.6)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    // Subtle bounce on active stages
                    .scaleEffect(isActive && i == streakDays - 1 ? 1.0 : 1.0)
                }
            }
            .frame(height: 100)
            .padding(.vertical, 4)

            // Progress bar with trailing pill
            StreakProgressBar(streakDays: streakDays, totalDays: 7)
        }
    }
}

// MARK: - Streak Progress Bar

struct StreakProgressBar: View {
    let streakDays: Int
    let totalDays: Int

    private var progress: CGFloat {
        min(CGFloat(streakDays) / CGFloat(totalDays), 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            let trackW  = geo.size.width
            let fillW   = max(trackW * progress, 64)
            let pillW: CGFloat = 80
            let barH: CGFloat = 40

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: barH / 2)
                    .fill(Color("orange").opacity(0.18))
                    .frame(width: trackW, height: barH)

                // Fill
                RoundedRectangle(cornerRadius: barH / 2)
                    .fill(
                        LinearGradient(
                            colors: [Color("yellow").opacity(0.9), Color("orange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillW, height: barH)

                // Trailing pill — anchored to the right edge of the fill
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: fillW - pillW + 2)

                    Text("\(streakDays) days")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(width: pillW, height: barH)
                        .background(
                            RoundedRectangle(cornerRadius: barH / 2)
                                .fill(Color("orange"))
                                .shadow(color: Color("orange").opacity(0.35),
                                        radius: 6, x: 0, y: 3)
                        )
                }
                .frame(width: trackW, alignment: .leading)
            }
        }
        .frame(height: 40)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: streakDays)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StreakView()
    }
    .modelContainer(for: MealLog.self, inMemory: true)
}
