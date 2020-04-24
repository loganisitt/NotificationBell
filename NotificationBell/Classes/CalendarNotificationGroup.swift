//
//  CalendarNotificationGroup.swift
//  Created by Logan Isitt on 4/23/20.
//

import Foundation

public class CalendarNotificationGroup: NotificationGroup {

    // MARK: - Properties

    public var notifications: [CalendarNotification]

    public var content: UNNotificationContent? {
        return notifications.first?.content
    }

    public var hour: Int? {
        return notifications.first.flatMap({ $0.dateComponents.hour })
    }

    public var minute: Int? {
        return notifications.first.flatMap({ $0.dateComponents.minute })
    }

    // MARK: - Initialization

    public init(notifications: [CalendarNotification]) {
        self.notifications = notifications
    }

    // MARK: - Dates

    public func nextTriggerDate() -> Date? {
        let sortedNotifications = notifications.sorted { (lhsNotification, rhsNotification) -> Bool in
            guard
                let lhsDate = lhsNotification.date,
                let rhsDate = rhsNotification.date
                else {
                    return false
            }
            return lhsDate < rhsDate
        }

        return sortedNotifications.first?.date
    }

    public func weekdays() -> Set<Int> {
        let weekdays = notifications.compactMap({ $0.dateComponents.weekday })
        return weekdays.isEmpty ? Set([0, 1, 2, 3, 4, 5, 6]) : Set(weekdays)
    }

    public func add(weekday: Int) {
        guard let dateComponents = notifications.first?.dateComponents, let content = content else { return }

        if weekdays().count + 1 == 7 {

            var reducedDateComponents = dateComponents
            reducedDateComponents.weekday = nil

            let newNotification = CalendarNotification(content: content, dateComponents: reducedDateComponents)
            NotificationBell.create(calendarNotification: newNotification)

            let identifiers = notifications.map({ $0.identifier })
            NotificationBell.deleteNotifications(with: identifiers)

            notifications = [newNotification]
        } else {
            var reducedDateComponents = dateComponents
            reducedDateComponents.weekday = weekday

            let newNotification = CalendarNotification(content: content, dateComponents: reducedDateComponents)
            NotificationBell.create(calendarNotification: newNotification)

            notifications.append(newNotification)
        }
    }

    public func remove(weekday: Int) {
        if notifications.count == 1 {

            let everyWeekdayNotification = notifications.removeFirst()

            var weekdays = Set([0, 1, 2, 3, 4, 5, 6])
            weekdays.remove(weekday)

            weekdays.forEach { (weekday) in
                var dateComponents = everyWeekdayNotification.dateComponents
                dateComponents.weekday = weekday

                let newNotification = CalendarNotification(content: everyWeekdayNotification.content, dateComponents: dateComponents)

                NotificationBell.create(calendarNotification: newNotification)

                notifications.append(newNotification)
            }

        } else {
            guard let index = notifications.firstIndex(where: { $0.dateComponents.weekday == weekday }) else { return }

            let deletedNotification = notifications.remove(at: index)

            NotificationBell.deleteNotifications(with: [deletedNotification.identifier])
        }
    }

    public func updateTimeFrom(dateComponents: DateComponents) {
        guard let hour = dateComponents.hour, let minute = dateComponents.minute else { return }

        notifications.enumerated().forEach { (index, notification) in

            var dateComponents = notification.dateComponents
            let content = notification.content

            dateComponents.hour = hour
            dateComponents.minute = minute

            let newNotification = CalendarNotification(content: content, dateComponents: dateComponents)
            NotificationBell.deleteNotifications(with: [notification.identifier])
            NotificationBell.create(calendarNotification: newNotification)

            notifications[index] = newNotification
        }
    }

    // MARK: - Helpers

    static func group(notifications: [CalendarNotification], by components: Set<Calendar.Component>) -> [CalendarNotificationGroup] {

        let calendar = Calendar.current

        var groupings = [DateComponents: [CalendarNotification]]()

        notifications.forEach { (notification) in
            guard let notificationDate = notification.date else { return }
            let dateComponents = calendar.dateComponents(components, from: notificationDate)

            if groupings[dateComponents] == nil {
                groupings[dateComponents] = [notification]
            } else {
                groupings[dateComponents]?.append(notification)
            }
        }

        let notificationGroups = groupings.compactMap({ CalendarNotificationGroup(notifications: $1) })

        return notificationGroups.sorted()
    }
}

extension CalendarNotificationGroup: Comparable {

    public static func < (lhs: CalendarNotificationGroup, rhs: CalendarNotificationGroup) -> Bool {
        guard let lhsHour = lhs.hour, let lhsMinute = lhs.minute else {
            return false
        }

        guard let rhsHour = rhs.hour, let rhsMinute = rhs.minute else {
            return true
        }

        if lhsHour < rhsHour {
            return true
        } else if rhsHour < lhsHour {
            return false
        } else {
            return lhsMinute < rhsMinute
        }
    }

    public static func == (lhs: CalendarNotificationGroup, rhs: CalendarNotificationGroup) -> Bool {
        guard
            let lhsHour = lhs.hour,
            let lhsMinute = lhs.minute,
            let rhsHour = rhs.hour,
            let rhsMinute = rhs.minute
            else {
                return false
        }

        return lhsHour == rhsHour && lhsMinute == rhsMinute
    }
}

