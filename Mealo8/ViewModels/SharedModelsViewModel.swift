//
//  SplashScreenViewModel.swift
//  Mealo8
//
//  Created by Rahaf on 11/06/2026.
//
import SwiftUI

// MARK: - Models & Data
struct MealEntry: Identifiable {
   let id = UUID()
   var icon: String
   var label: String
   var startTime: Date
   var endTime: Date
   var iconActivated: Bool = false
   var timeActivated: Bool = false
}

let mealIcons: [(emoji: String, label: String, defaultHour: Int)] = [
   ("🌤️", "Morning meal",   8),
   ("☀️",  "Midday meal",   12),
   ("🌅",  "Evening meal",  18),
   ("🍎",  "Snack",         15),
]

struct IdentifiableIndex: Identifiable {
    let value: Int
    var id: Int { value }
}

func makeTime(hour: Int) -> Date {
    Calendar.current.date(bySettingHour: min(hour, 23), minute: 0, second: 0, of: Date()) ?? Date()
}

func formatTime(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f.string(from: date)
}
