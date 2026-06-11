//
//  Mealo8App.swift
//  Mealo8
//

import SwiftUI
import SwiftData
import UserNotifications

enum AppScreen {
    case splash
    case onboarding
    case promise
    case home
}

@main
struct Mealo8App: App {

    let container: ModelContainer = {
        let schema = Schema([MealLog.self, UserProfile.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    WatchSyncManager.shared.modelContext = container.mainContext
                    UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound]) { _, _ in }
                }
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @Query private var profiles: [UserProfile]
    @State private var screen: AppScreen = .splash

    private var hasCompletedOnboarding: Bool { !profiles.isEmpty }

    var body: some View {
        Group {
            switch screen {
            case .splash:
                SplashView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        screen = hasCompletedOnboarding ? .home : .onboarding
                    }
                }
            case .onboarding:
                SetYourPlanView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        screen = .promise
                    }
                }
            case .promise:
                PromiseView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        screen = .home
                    }
                }
            case .home:
                HomepageView()
            }
        }
    }
}
