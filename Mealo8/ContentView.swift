//  ContentView.swift
//  Mealo8
//
//  Root view — no tab bar.
//  HomepageView owns its own NavigationStack, so nothing extra is needed here.
//  Navigation flow:
//    HomepageView  ──(tap 🔥N)──▶ StreakView      (sheet)
//    HomepageView  ──(tap insight card)──▶ InsightsView  (push)
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomepageView()
    }
}

#Preview {
    ContentView()
}
