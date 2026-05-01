import Foundation
import UserNotifications

enum NotificationService {

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    // MARK: - Project Deadline Notifications

    static func scheduleDeadline(for project: Project) {
        cancelNotifications(for: project.id)

        guard let deadline = project.deadline, project.status != .killed && project.status != .shipped else {
            return
        }

        let alerts: [(days: Int, body: String)] = [
            (7, "\(project.name): 7 days until deadline"),
            (3, "\(project.name): 3 days left -- crunch time"),
            (1, "\(project.name): deadline is TOMORROW"),
            (0, "\(project.name): deadline is TODAY -- ship or kill")
        ]

        for alert in alerts {
            guard let triggerDate = Calendar.current.date(byAdding: .day, value: -alert.days, to: deadline),
                  triggerDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "FORGE"
            content.body = alert.body
            content.sound = .default

            var comps = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
            comps.hour = 9
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let request = UNNotificationRequest(
                identifier: "\(project.id.uuidString)-\(alert.days)d",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Skill Target Notifications

    static func scheduleTarget(for skill: SkillTrack) {
        cancelNotifications(for: skill.id)

        guard let target = skill.targetDate, skill.status != .acquired else {
            return
        }

        let alerts: [(days: Int, body: String)] = [
            (7, "\(skill.name): 7 days to target"),
            (3, "\(skill.name): 3 days left on target"),
            (1, "\(skill.name): target is TOMORROW"),
            (0, "\(skill.name): target date is TODAY")
        ]

        for alert in alerts {
            guard let triggerDate = Calendar.current.date(byAdding: .day, value: -alert.days, to: target),
                  triggerDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "FORGE SKILLS"
            content.body = alert.body
            content.sound = .default

            var comps = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
            comps.hour = 9
            comps.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

            let request = UNNotificationRequest(
                identifier: "\(skill.id.uuidString)-\(alert.days)d",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Cancel

    static func cancelNotifications(for id: UUID) {
        let ids = [0, 1, 3, 7].map { "\(id.uuidString)-\($0)d" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
