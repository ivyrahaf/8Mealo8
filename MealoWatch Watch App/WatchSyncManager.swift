//
//  WatchSyncManager.swift
//  MealoWatch Watch App (Watch target ONLY)
//

import Foundation
import WatchConnectivity
import SwiftData

final class WatchSyncManager: NSObject, WCSessionDelegate {

    static let shared = WatchSyncManager()
    var modelContext: ModelContext?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendMealToPhone(mealName: String, mood: String) {
        guard WCSession.default.activationState == .activated else { return }
        let msg: [String: Any] = [
            "action":   "logMeal",
            "mealName": mealName,
            "mood":     mood,
            "date":     Date().timeIntervalSince1970
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(msg, replyHandler: nil)
        } else {
            WCSession.default.transferUserInfo(msg)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncoming(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleIncoming(userInfo)
    }

    private func handleIncoming(_ data: [String: Any]) {
        guard let action   = data["action"] as? String, action == "logMeal",
              let mealName = data["mealName"] as? String,
              let moodRaw  = data["mood"] as? String,
              let mood     = WatchMood(rawValue: moodRaw.lowercased()),
              let timestamp = data["date"] as? TimeInterval
        else { return }

        DispatchQueue.main.async { [weak self] in
            guard let ctx = self?.modelContext else { return }
            let log = WatchMealLog(date: Date(timeIntervalSince1970: timestamp), mood: mood, mealName: mealName)
            ctx.insert(log)
            try? ctx.save()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
}
