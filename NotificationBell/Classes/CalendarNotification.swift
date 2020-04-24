//
//  CalendarNotification.swift
//  Created by Logan Isitt on 4/23/20.
//

import UserNotifications

public class CalendarNotification {

    // MARK: - Properties

    public let identifier: String

    public let content: UNNotificationContent

    public var dateComponents: DateComponents

    public var date: Date? {
        return Calendar.current.date(from: dateComponents)
    }

    // MARK: - Initialization

    public init?(notificationRequest: UNNotificationRequest) {
        guard let trigger = notificationRequest.trigger as? UNCalendarNotificationTrigger else { return nil }

        self.identifier = notificationRequest.identifier
        self.content = notificationRequest.content
        self.dateComponents = trigger.dateComponents
    }

    public init(content: UNNotificationContent, dateComponents: DateComponents) {
        self.identifier = String(format: "%i", dateComponents.hashValue)
        self.content = content
        self.dateComponents = dateComponents
    }
}
