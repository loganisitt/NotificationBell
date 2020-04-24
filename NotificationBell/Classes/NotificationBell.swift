import UserNotifications

public enum NotificationBell {

    public static func getNotificationGroups(completionHandler: @escaping (([NotificationGroup]) -> Void)) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            completionHandler(NotificationBell.makeGroups(from: requests))
        }
    }

    private static func makeGroups(from notificationRequests: [UNNotificationRequest]) -> [NotificationGroup] {

        let calendarNotifications = notificationRequests.compactMap({ CalendarNotification(notificationRequest: $0) })
        let calendarGroups = CalendarNotificationGroup.group(notifications: calendarNotifications, by: [.hour, .minute])

        return calendarGroups
    }

    public static func deleteNotifications(with identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    public static func create(calendarNotification: CalendarNotification) {

        let content = calendarNotification.content
        let dateComponents = calendarNotification.dateComponents

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: calendarNotification.identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                Log.error(error)
            } else {
                Log.message("Notification(\(calendarNotification.identifier) added successfully.")
            }
        }
    }
}

fileprivate enum Log {

    static func message(_ message: String) {
        print("[NotificationBell] \(message)")
    }

    static func error(_ error: Error) {
        print("[NotificationBell] \(error.localizedDescription)")
    }
}
