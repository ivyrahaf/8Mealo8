//
//  LT.swift
//  Mealo8
//
//  Created by Rahaf on 11/06/2026.
//


import SwiftUI
import SwiftData
import Combine

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Design tokens  (mirrors InsightsView tokens)
// ─────────────────────────────────────────────────────────────────────────────

private enum LT {
    static let bg      = Color("background")
    static let card    = Color("yellow")
    static let accent  = Color("orange")
    static let text    = Color("brown")
    static let muted   = Color("brown").opacity(0.5)
    static let border  = Color("button")

    static let xs: CGFloat =  4
    static let sm: CGFloat =  8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - LogMealView
// ─────────────────────────────────────────────────────────────────────────────

struct LogMealView: View {

    // Injected by the caller — close the sheet when done
    var onDismiss: () -> Void = {}

    @Environment(\.modelContext) private var context
    @StateObject private var vm = LogMealViewModel()

    var body: some View {
        ZStack {
            LT.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                dragHandle
                    .padding(.top, LT.md)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: LT.xl) {
                        headerSection
                        moodSection
                        noteSection
                        logButton
                        Spacer(minLength: LT.xl)
                    }
                    .padding(.horizontal, LT.md)
                    .padding(.top, LT.lg)
                }
            }
        }
        .alert("Meal logged! 🍊", isPresented: $vm.didSave) {
            Button("Great!", role: .cancel) { onDismiss() }
        } message: {
            Text("Your check-in has been saved.")
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Drag handle
    // ─────────────────────────────────────────────────────────────

    private var dragHandle: some View {
        Capsule()
            .fill(LT.border)
            .frame(width: 40, height: 4)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Header
    // ─────────────────────────────────────────────────────────────

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: LT.xs) {
                Text("How are you feeling?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(LT.text)

                Text("Log a meal check-in to track your nourishment rhythm.")
                    .font(.system(size: 14))
                    .foregroundColor(LT.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image("ch1")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
        }
        .padding(LT.lg)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(LT.card))
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Mood picker
    // ─────────────────────────────────────────────────────────────

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: LT.md) {
            Text("Pick your mood")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(LT.text)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: LT.sm), count: 2),
                spacing: LT.sm
            ) {
                ForEach(MoodState.allCases, id: \.self) { mood in
                    MoodTile(
                        mood: mood,
                        isSelected: vm.selectedMood == mood
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            vm.selectedMood = mood
                        }
                    }
                }
            }
        }
        .padding(LT.lg)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(LT.card))
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Optional note
    // ─────────────────────────────────────────────────────────────

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: LT.sm) {
            Text("Add a note  (optional)")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(LT.text)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LT.bg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(LT.border, lineWidth: 1)
                    )

                if vm.note.isEmpty {
                    Text("e.g. Had a big lunch, feeling satisfied…")
                        .font(.system(size: 14))
                        .foregroundColor(LT.muted)
                        .padding(LT.md)
                }

                TextEditor(text: $vm.note)
                    .font(.system(size: 14))
                    .foregroundColor(LT.text)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .padding(LT.sm)
                    .frame(minHeight: 80)
            }
            .frame(minHeight: 100)
        }
        .padding(LT.lg)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(LT.card))
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: Log button
    // ─────────────────────────────────────────────────────────────

    private var logButton: some View {
        Button {
            vm.save(context: context)
        } label: {
            HStack(spacing: LT.sm) {
                if vm.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Log Meal Check-in")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Capsule()
                    .fill(vm.selectedMood != nil ? LT.accent : LT.border)
            )
            .animation(.easeInOut(duration: 0.2), value: vm.selectedMood)
        }
        .disabled(vm.selectedMood == nil || vm.isSaving)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - MoodTile
// ─────────────────────────────────────────────────────────────────────────────

private struct MoodTile: View {
    let mood:       MoodState
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(mood.emoji)
                    .font(.system(size: 24))

                Text(mood.label)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : Color("brown"))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? mood.color : Color("background"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? mood.color : Color("button"), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - LogMealViewModel
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
final class LogMealViewModel: ObservableObject {

    @Published var selectedMood: MoodState? = nil
    @Published var note:         String     = ""
    @Published var isSaving:     Bool       = false
    @Published var didSave:      Bool       = false
    @Published var errorMessage: String?    = nil

    func save(context: ModelContext) {
        guard let mood = selectedMood else { return }
        isSaving = true

        let log = MealLog(date: Date(), mood: mood, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(log)

        do {
            try context.save()
            didSave  = true
        } catch {
            errorMessage = "Couldn't save your log. Please try again."
        }
        isSaving = false
    }

    func reset() {
        selectedMood = nil
        note         = ""
        isSaving     = false
        didSave      = false
        errorMessage = nil
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────────────────────────────────────

#Preview {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MealLog.self, UserProfile.self,
                                        configurations: config)
    return LogMealView()
        .modelContainer(container)
}