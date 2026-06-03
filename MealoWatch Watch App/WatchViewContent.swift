//
//  WatchViewContent.swift
//  Mealo Watch App Watch App
//

import SwiftUI
import SwiftData

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
