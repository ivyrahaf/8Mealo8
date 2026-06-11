//
//  SetYourPlanView.swift
//  Mealo8
//

import SwiftUI
import SwiftData

struct SetYourPlanView: View {
    var onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @AppStorage("userName") private var storedName: String = "Friend"

    @State private var userName: String = ""
    @State private var mealCount: Double = 0
    @State private var meals: [MealEntry] = []
    @State private var selectedDays: Int? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("background").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        Text("Set your plan")
                            .font(.custom("Georgia", size: 29))
                            .foregroundColor(Color("orange"))
                            .padding(.bottom, 30)

                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Your name", text: $userName)
                                .font(.system(size: 15))
                                .foregroundColor(Color("brown"))
                                .padding(12)
                                .background(Color.white.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.bottom, 35)

                        Text("How many meals do you want to track each day?")
                            .font(.system(size: 12))
                            .foregroundColor(Color("brown").opacity(0.45))
                            .padding(.bottom, 8)

                        sliderSection
                        
                        Spacer(minLength: 20)
                        howLongSection
                            .opacity(meals.isEmpty ? 0.35 : 1)
                            .disabled(meals.isEmpty)
                            .animation(.easeInOut(duration: 0.3), value: meals.isEmpty)
                        
                        Spacer(minLength: 32)

                        if !meals.isEmpty && selectedDays != nil {
                            Text("\(Int(mealCount)) meals · \(selectedDays!) days")
                                .font(.system(size: 12))
                                .foregroundColor(Color("brown").opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom, 10)
                            
                            NavigationLink {
                                CustomizeMealsView(meals: $meals, onDone: {
                                    // Save name to @AppStorage for homepage greeting
                                    let finalName = userName.trimmingCharacters(in: .whitespaces)
                                    storedName = finalName.isEmpty ? "Friend" : finalName

                                    // Also save UserProfile for InsightsView
                                    let profile = UserProfile(
                                        name: storedName,
                                        signupDate: Date(),
                                        dailyMealGoal: Int(mealCount)
                                    )
                                    modelContext.insert(profile)
                                    try? modelContext.save()
                                    onDone()
                                })
                            } label: {
                                Text("Continue ")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color("orange"))
                                    .clipShape(Capsule())
                                    .shadow(color: Color("orange").opacity(0.3), radius: 10, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 56)
                    .padding(.bottom, 100)
                }
                
                VStack {
                    Spacer()
                    Image("Point1")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 32)
                }
            }
        }
    }
    
    var sliderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MEALS PER DAY")
                    .font(.system(size: 11))
                    .foregroundColor(Color("orange").opacity(0.45))
                    .kerning(1.2)
                Spacer()
                Text("\(Int(mealCount))")
                    .font(.custom("Georgia", size: 18))
                    .foregroundColor(Color("orange"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 3)
                    .background(Color("orange").opacity(0.1))
                    .clipShape(Capsule())
                    .animation(.spring(response: 0.3), value: mealCount)
            }
            
            Slider(value: $mealCount, in: 1...4, step: 1)
                .tint(Color("orange"))
                .onChange(of: mealCount) { newVal in
                    let count = Int(newVal)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        if count > meals.count {
                            for i in meals.count..<count {
                                let ic = mealIcons[i % mealIcons.count]
                                meals.append(MealEntry(
                                    icon: ic.emoji,
                                    label: ic.label,
                                    startTime: makeTime(hour: ic.defaultHour),
                                    endTime:   makeTime(hour: ic.defaultHour + 1)
                                ))
                            }
                        } else {
                            meals.removeLast(meals.count - count)
                        }
                    }
                }
            
            HStack {
                ForEach(1...4, id: \.self) { n in
                    Text("\(n)")
                        .font(.system(size: 10, weight: Int(mealCount) >= n ? .semibold : .regular))
                        .foregroundColor(Int(mealCount) >= n ? Color("orange") : Color("orange").opacity(0.35))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.bottom, 12)
    }
    
    var howLongSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOW LONG?")
                .font(.system(size: 11))
                .foregroundColor(Color("orange").opacity(0.45))
                .kerning(1.2)
            
            HStack(spacing: 8) {
                ForEach([30, 66, 90], id: \.self) { days in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedDays = days }
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(days)")
                                .font(.custom("Georgia", size: 22))
                            Text("days")
                                .font(.system(size: 11))
                                .opacity(0.75)
                        }
                        .foregroundColor(selectedDays == days ? .white : Color("orange"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedDays == days ? Color("orange") : Color("orange").opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color("orange").opacity(0.25), lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.bottom, 28)
    }
}

#Preview {
    SetYourPlanView(onDone: {})
}
