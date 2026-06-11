//
//  SplashScreenViewModel.swift
//  Mealo8
//
//  Created by Rahaf on 11/06/2026.
//
import SwiftUI
import SwiftData

struct SplashView: View {
    var onGetStarted: () -> Void
    
    @State private var characterOffset: CGFloat = 300
    @State private var characterOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            Color("background")

            VStack(spacing: 0) {
                Spacer()

                Image("ch1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .offset(y: characterOffset)
                    .opacity(characterOpacity)

                Spacer().frame(height: 32)

                Text("Mealo")
                    .font(.custom("Georgia", size: 42))
                    .foregroundColor(Color("orange"))
                    .fontWeight(.bold)

                Spacer().frame(height: 12)

                VStack(spacing: 4) {
                    Text("Skipping meals isn't a choice, it's a habit")
                    Text("Let's build a better one.")
                }
                .font(.custom("Georgia", size: 14))
                .foregroundColor(Color("brown").opacity(0.7))
                .multilineTextAlignment(.center)
                .opacity(textOpacity)

                Spacer().frame(height: 16)

                Text("No pressure, just progress!")
                    .font(.system(size: 13))
                    .foregroundColor(Color("orange").opacity(0.5))
                    .opacity(textOpacity)

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                characterOffset = 0
                characterOpacity = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.2)) {
                    characterOffset = -30
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        characterOffset = 0
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.4)) {
                    textOpacity = 1
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onGetStarted()
            }
        }
    }
}

#Preview {
    SplashView(onGetStarted: {})
}

#Preview("Full Flow") {
    ContentFlowPreview()
        .modelContainer(for: [MealLog.self, UserProfile.self], inMemory: true)
}

struct ContentFlowPreview: View {
    @State private var screen: AppScreen = .splash
    
    var body: some View {
        Group {
            switch screen {
            case .splash:
                SplashView {
                    withAnimation { screen = .onboarding }
                }
            case .onboarding:
                SetYourPlanView {
                    withAnimation { screen = .promise }
                }
            case .promise:
                PromiseView {
                    withAnimation { screen = .home }
                }
            case .home:
                HomepageView()
            }
        }
    }
}
