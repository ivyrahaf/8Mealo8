//
//  WatchViewContent.swift
//  MealoWatch Watch App
//

import SwiftUI

struct WatchContentView: View {
    var body: some View {
        TabView {
            WatchStateView()
            WatchLogFoodView()
            WatchStreakView()
            WatchAnalyticsView()
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}
