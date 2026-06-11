//
//  CustomizeMealsView.swift
//  Mealo8
//
//  Created by Rahaf on 11/06/2026.
//

import SwiftUI

// MARK: - PAGE 2: Customize Meals View
struct CustomizeMealsView: View {
  @Binding var meals: [MealEntry]
  var onDone: () -> Void
  
  @State private var activeMealIndex: Int? = nil
  
  var body: some View {
      ZStack {
          Color("background").ignoresSafeArea()
          
          ScrollView(showsIndicators: false) {
              VStack(alignment: .leading, spacing: 0) {
                  
                  Text("Customize your meals")
                      .font(.custom("Georgia", size: 30))
                      .foregroundColor(Color("orange"))
                      .padding(.bottom, 4)
                  
                  Text("Tap any card to customize it")
                      .font(.system(size: 15, weight: .medium))
                      .foregroundColor(Color("brown").opacity(0.6))
                      .padding(.bottom, 24)
                  
                  VStack(spacing: 20) {
                      ForEach(meals.indices, id: \.self) { i in
                          MealBoxView(
                              meal: $meals[i],
                              onTap: { activeMealIndex = i }
                          )
                          .id(meals[i].icon + meals[i].label)
                      }
                  }
                  .padding(.bottom, 140)
              }
              .padding(.horizontal, 24)
              .padding(.top, 56)
          }
          
          VStack {
              Spacer()
              
              Button(action: onDone) {
                  Text("Start my journey →")
                      .font(.system(size: 15, weight: .medium))
                      .foregroundColor(.white)
                      .frame(maxWidth: .infinity)
                      .padding(.vertical, 16)
                      .background(Color("orange"))
                      .clipShape(Capsule())
                      .shadow(color: Color("orange").opacity(0.3), radius: 10, x: 0, y: 4)
              }
              .padding(.horizontal, 24)
              .padding(.top, 56)
              .padding(.bottom, 100)
              Image("Point2")
                  .frame(maxWidth: .infinity, alignment: .center)
                  .padding(.bottom, 32)
          }
      }
      .sheet(item: Binding(
          get: { activeMealIndex.map { IdentifiableIndex(value: $0) } },
          set: { activeMealIndex = $0?.value }
      )) { idx in
          MealEditSheet(meal: $meals[idx.value])
              .presentationDetents([.height(380)])
              .presentationDragIndicator(.visible)
              .presentationBackground(Color("background"))
      }
  }
}

// MARK: - MealBoxView
struct MealBoxView: View {
  @Binding var meal: MealEntry
  var onTap: () -> Void
  
  var body: some View {
      Button(action: onTap) {
          HStack(spacing: 14) {
              Text(meal.icon)
                  .font(.system(size: 28))
                  .frame(width: 48, height: 48)
                  .background(Color("orange").opacity(0.08))
                  .clipShape(RoundedRectangle(cornerRadius: 12))
              
              VStack(alignment: .leading, spacing: 3) {
                  Text(meal.label)
                      .font(.system(size: 14, weight: .semibold))
                      .foregroundColor(Color("brown"))
                  
                  Text("\(formatTime(meal.startTime)) – \(formatTime(meal.endTime))")
                      .font(.system(size: 11))
                      .foregroundColor(Color("brown").opacity(0.45))
              }
              
              Spacer()
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 12)
          .background(Color.white.opacity(0.6))
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .overlay(
              RoundedRectangle(cornerRadius: 16)
                  .stroke(Color("orange").opacity(0.12), lineWidth: 1.5)
          )
      }
      .buttonStyle(.plain)
  }
}

// MARK: - Meal Edit Sheet
struct MealEditSheet: View {
  @Binding var meal: MealEntry
  @Environment(\.dismiss) var dismiss
  
  var currentIndex: Int {
      mealIcons.firstIndex(where: { $0.emoji == meal.icon }) ?? 0
  }
  
  var startRange: ClosedRange<Date> {
      let cal = Calendar.current
      let now = Date()
      switch meal.label {
      case "Morning meal":
          let start = cal.date(bySettingHour: 5,  minute: 0, second: 0, of: now)!
          let end   = cal.date(bySettingHour: 11, minute: 59, second: 0, of: now)!
          return start...end
      case "Evening meal":
          let start = cal.date(bySettingHour: 12, minute: 0, second: 0, of: now)!
          let end   = cal.date(bySettingHour: 23, minute: 59, second: 0, of: now)!
          return start...end
      default:
          let start = cal.date(bySettingHour: 0, minute: 0, second: 0, of: now)!
          let end   = cal.date(bySettingHour: 23, minute: 59, second: 0, of: now)!
          return start...end
      }
  }
  
  var body: some View {
      VStack(spacing: 0) {
          
          VStack(spacing: 6) {
              Text("CHOOSE ICON & NAME")
                  .font(.system(size: 10))
                  .foregroundColor(Color("brown").opacity(0.5))
                  .kerning(1.2)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.horizontal, 24)
                  .padding(.top, 20)
              
              HStack(spacing: 0) {
                  Button {
                      let newIdx = (currentIndex - 1 + mealIcons.count) % mealIcons.count
                      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                          meal.icon  = mealIcons[newIdx].emoji
                          meal.label = mealIcons[newIdx].label
                      }
                  } label: {
                      Image(systemName: "chevron.left")
                          .font(.system(size: 16, weight: .semibold))
                          .foregroundColor(Color("orange"))
                          .frame(width: 44, height: 44)
                          .background(Color("orange").opacity(0.1))
                          .clipShape(Circle())
                  }
                  
                  Spacer()
                  
                  VStack(spacing: 6) {
                      Text(meal.icon)
                          .font(.system(size: 44))
                          .id(meal.icon)
                          .transition(.scale(scale: 0.7).combined(with: .opacity))
                      
                      Text(meal.label)
                          .font(.system(size: 15, weight: .semibold))
                          .foregroundColor(Color("brown"))
                          .id(meal.label)
                          .transition(.opacity)
                  }
                  
                  Spacer()
                  
                  Button {
                      let newIdx = (currentIndex + 1) % mealIcons.count
                      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                          meal.icon  = mealIcons[newIdx].emoji
                          meal.label = mealIcons[newIdx].label
                      }
                  } label: {
                      Image(systemName: "chevron.right")
                          .font(.system(size: 16, weight: .semibold))
                          .foregroundColor(Color("orange"))
                          .frame(width: 44, height: 44)
                          .background(Color("orange").opacity(0.1))
                          .clipShape(Circle())
                  }
              }
              .padding(.horizontal, 32)
              .padding(.vertical, 12)
              .background(Color("orange").opacity(0.05))
              .clipShape(RoundedRectangle(cornerRadius: 18))
              .padding(.horizontal, 24)
          }
          
          Divider()
              .padding(.vertical, 16)
              .padding(.horizontal, 24)
          
          VStack(spacing: 16) {
              Text("Set reminder")
                  .font(.custom("Georgia", size: 18))
                  .foregroundColor(Color("brown"))
              
              HStack(spacing: 32) {
                  VStack(spacing: 8) {
                      Text("START")
                          .font(.system(size: 11))
                          .foregroundColor(Color("orange"))
                          .kerning(1)
                      
                      DatePicker("", selection: $meal.startTime, in: startRange, displayedComponents: .hourAndMinute)
                          .datePickerStyle(.compact)
                          .labelsHidden()
                          .tint(Color("orange"))
                  }
                  
                  Text("→")
                      .foregroundColor(Color("orange").opacity(0.4))
                  
                  VStack(spacing: 8) {
                      Text("END")
                          .font(.system(size: 11))
                          .foregroundColor(Color("orange"))
                          .kerning(1)
                      
                      DatePicker("", selection: $meal.endTime, displayedComponents: .hourAndMinute)
                          .datePickerStyle(.compact)
                          .labelsHidden()
                          .tint(Color("orange"))
                  }
              }
          }
          .padding(.horizontal, 24)
          
          Spacer()
          
          Button {
              withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                  meal.timeActivated = true
                  meal.iconActivated = true
              }
              scheduleMealNotifications(for: [meal])
              dismiss()
          } label: {
              Text("Done")
                  .font(.system(size: 15, weight: .medium))
                  .foregroundColor(.white)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 14)
                  .background(Color("orange"))
                  .clipShape(Capsule())
                  .shadow(color: Color("orange").opacity(0.3), radius: 10, x: 0, y: 4)
          }
          .buttonStyle(.plain)
          .padding(.horizontal, 24)
          .padding(.bottom, 24)
      }
  }
}

// MARK: - Time Diff Helper
func timeDiff(_ start: Date, _ end: Date) -> String {
  let diff = Int(end.timeIntervalSince(start) / 60)
  let absDiff = abs(diff)
  if absDiff < 60 {
      return "\(absDiff)m"
  } else if absDiff % 60 == 0 {
      return "\(absDiff / 60)h"
  } else {
      return "\(absDiff / 60)h\(absDiff % 60)m"
  }
}

#Preview {
  CustomizeMealsView(meals: .constant([
      MealEntry(icon: "🌤️", label: "Morning meal", startTime: makeTime(hour: 8),  endTime: makeTime(hour: 9)),
      MealEntry(icon: "☀️", label: "Midday meal", startTime: makeTime(hour: 12), endTime: makeTime(hour: 13)),
      MealEntry(icon: "🌅", label: "Evening meal", startTime: makeTime(hour: 18), endTime: makeTime(hour: 19)),
      MealEntry(icon: "🍎", label: "Snack", startTime: makeTime(hour: 15), endTime: makeTime(hour: 16))
  ]), onDone: {})
}
