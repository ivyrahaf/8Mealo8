//
//  Notfications.swift
//  Mealo8
//
//  Created by Rahaf on 11/06/2026.
//
import UserNotifications

func scheduleMealNotifications(for meals: [MealEntry]) {
    let center = UNUserNotificationCenter.current()
    center.removeAllPendingNotificationRequests()
    
    for meal in meals {
        let content = UNMutableNotificationContent()
        content.title = "\(meal.icon) \(meal.label)"
        content.body = "Time for your \(meal.label.lowercased())! 🍊"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: meal.startTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: meal.id.uuidString,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}
