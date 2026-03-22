//
//  NotificationScheduler.swift
//  CBED
//

import Foundation
import UserNotifications

final class NotificationScheduler {
    struct ScheduleSettings: Codable {
        let isEnabled: Bool
        let inactivityDays: Int
        let countdownDays: [Int]
        let targets: [CountdownTarget]
        let debugInactivityDelaySeconds: Int?
        let debugCountdownDelaySeconds: Int?
    }

    struct CountdownTarget: Codable {
        let identifier: String
        let title: String
        let bodyTemplate: String?
        let isoDate: String
    }

    static let shared = NotificationScheduler()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let calendar = Calendar.current
    private let defaultConfigName = "main config"
    private let defaultInactivityDays = 3
    private let defaultCountdownDays = [30, 14, 7, 3, 1]
    private let minimumReminderHour = 8
    private let maximumReminderHour = 20

    private init() {}

    func applyTestingMode(isEnabled: Bool) {
        if isEnabled {
            let fallbackTarget = CountdownTarget(identifier: "test",
                                                 title: "Bar Exam Drills Test",
                                                 bodyTemplate: "This is a test countdown notification.",
                                                 isoDate: Date().addingTimeInterval(60).ISO8601Format())
            let baseSettings = Storage.notificationSchedule ?? ScheduleSettings(isEnabled: true,
                                                                                inactivityDays: 3,
                                                                                countdownDays: [1],
                                                                                targets: [fallbackTarget],
                                                                                debugInactivityDelaySeconds: nil,
                                                                                debugCountdownDelaySeconds: nil)
            let testSettings = ScheduleSettings(isEnabled: true,
                                                inactivityDays: 1,
                                                countdownDays: [0],
                                                targets: baseSettings.targets.isEmpty ? [fallbackTarget] : baseSettings.targets,
                                                debugInactivityDelaySeconds: 10,
                                                debugCountdownDelaySeconds: 15)
            scheduleIfAuthorized(using: testSettings)
        } else {
            clearManagedNotifications()
        }
    }

    func handleAppDidBecomeActive() {
        Storage.lastOpenedAt = Date()
        scheduleFromCacheIfPossible()
    }

    func update(using remoteConfigs: [[String: Any]]?, configName: String = "main config") {
        let resolvedName = configName.isEmpty ? defaultConfigName : configName
        guard let config = remoteConfigs?.first(where: { ($0["name"] as? String) == resolvedName }) else {
            return
        }

        let settings = buildSettings(from: config)
        Storage.notificationSchedule = settings
        scheduleIfAuthorized(using: settings)
    }

    private func scheduleFromCacheIfPossible() {
        guard let settings = Storage.notificationSchedule else {
            return
        }

        scheduleIfAuthorized(using: settings)
    }

    private func scheduleIfAuthorized(using settings: ScheduleSettings) {
        notificationCenter.getNotificationSettings { [weak self] authorizationSettings in
            guard let self = self else { return }

            switch authorizationSettings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.schedule(using: settings)
            case .notDetermined:
                self.notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    guard granted else { return }
                    self.schedule(using: settings)
                }
            case .denied:
                self.clearManagedNotifications()
            @unknown default:
                break
            }
        }
    }

    private func schedule(using settings: ScheduleSettings) {
        clearManagedNotifications()

        guard settings.isEnabled else {
            return
        }

        scheduleInactivityReminder(settings: settings)
        settings.targets.forEach { scheduleCountdowns(for: $0, settings: settings) }
    }

    private func clearManagedNotifications() {
        let identifiers = notificationIdentifiersForStoredTargets()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    private func notificationIdentifiersForStoredTargets() -> [String] {
        let baseIdentifiers = ["cbed.notification.inactivity"]
        let storedTargets = Storage.notificationSchedule?.targets ?? []
        let debugCountdownIdentifiers = storedTargets.map { "cbed.notification.debug.countdown.\($0.identifier)" }
        let countdownIdentifiers = storedTargets.flatMap { target in
            (Storage.notificationSchedule?.countdownDays ?? []).map { days in
                countdownIdentifier(for: target.identifier, daysBefore: days)
            }
        }

        return baseIdentifiers + debugCountdownIdentifiers + countdownIdentifiers
    }

    private func scheduleInactivityReminder(settings: ScheduleSettings) {
        let safeDays = max(1, settings.inactivityDays)
        let lastOpenedAt = Storage.lastOpenedAt ?? Date()

        let content = UNMutableNotificationContent()
        content.title = inactivityTitle()
        content.body = inactivityBody(daysSinceLastOpen: safeDays)
        content.sound = .default

        let trigger: UNNotificationTrigger
        if let debugDelaySeconds = settings.debugInactivityDelaySeconds, debugDelaySeconds > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(debugDelaySeconds), repeats: false)
        } else {
            guard let triggerDate = calendar.date(byAdding: .day, value: safeDays, to: lastOpenedAt) else {
                return
            }

            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute],
                                                         from: clampedReminderDate(from: triggerDate))
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        }

        let request = UNNotificationRequest(identifier: "cbed.notification.inactivity",
                                            content: content,
                                            trigger: trigger)
        notificationCenter.add(request)
    }

    private func inactivityBody(daysSinceLastOpen: Int) -> String {
        let daysText = daysSinceLastOpen == 1 ? "1 day" : "\(daysSinceLastOpen) days"
        return "Consistency is your best friend. It’s been \(daysText) since your last session—start your daily drills now!"
    }

    private func inactivityTitle() -> String {
        guard let daysUntilBar = assignedBarExamDaysUntil() else {
            return "Start your daily drills"
        }

        let dayText = daysUntilBar == 1 ? "1 day" : "\(daysUntilBar) days"
        return "\(dayText) until the Bar."
    }

    private func assignedBarExamDaysUntil() -> Int? {
        guard let memberPlan = Storage.profileInfo?.memberPlan else {
            return nil
        }

        let nextExamDate: Date?
        switch memberPlan {
        case .proBarFeb:
            nextExamDate = nextAssignedBarExamDate(forMonth: 2)
        case .proBarJul:
            nextExamDate = nextAssignedBarExamDate(forMonth: 7)
        default:
            nextExamDate = nil
        }

        guard let examDate = nextExamDate else {
            return nil
        }

        let startOfToday = calendar.startOfDay(for: Date())
        let startOfExamDay = calendar.startOfDay(for: examDate)
        let dayCount = calendar.dateComponents([.day], from: startOfToday, to: startOfExamDay).day ?? 0
        return max(dayCount, 0)
    }

    private func nextAssignedBarExamDate(forMonth month: Int) -> Date? {
        let currentYear = calendar.component(.year, from: Date())

        for year in [currentYear, currentYear + 1] {
            guard let examDate = lastTuesday(ofMonth: month, year: year) else {
                continue
            }

            if calendar.startOfDay(for: examDate) >= calendar.startOfDay(for: Date()) {
                return examDate
            }
        }

        return nil
    }

    private func lastTuesday(ofMonth month: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month + 1
        components.day = 0

        guard let lastDayOfMonth = calendar.date(from: components) else {
            return nil
        }

        var date = lastDayOfMonth
        while calendar.component(.weekday, from: date) != 3 {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else {
                return nil
            }
            date = previousDay
        }

        return date
    }

    private func scheduleCountdowns(for target: CountdownTarget, settings: ScheduleSettings) {
        if let debugDelaySeconds = settings.debugCountdownDelaySeconds, debugDelaySeconds > 0 {
            scheduleDebugCountdown(for: target, delaySeconds: debugDelaySeconds)
            return
        }

        guard let targetDate = parseDate(target.isoDate) else {
            return
        }

        let uniqueOffsets = Array(Set(settings.countdownDays)).sorted(by: >)
        uniqueOffsets.forEach { daysBefore in
            guard daysBefore >= 0,
                  let scheduledDate = calendar.date(byAdding: .day, value: -daysBefore, to: targetDate) else {
                return
            }

            let fireDate = normalizedNotificationDate(from: scheduledDate)
            guard fireDate > Date() else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = target.title
            content.body = countdownBody(for: target, daysBefore: daysBefore)
            content.sound = .default

            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: countdownIdentifier(for: target.identifier, daysBefore: daysBefore),
                                                content: content,
                                                trigger: trigger)
            notificationCenter.add(request)
        }
    }

    private func scheduleDebugCountdown(for target: CountdownTarget, delaySeconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = target.title
        content.body = countdownBody(for: target, daysBefore: 0)
        content.sound = .default

        let request = UNNotificationRequest(identifier: "cbed.notification.debug.countdown.\(target.identifier)",
                                            content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(delaySeconds),
                                                                                       repeats: false))
        notificationCenter.add(request)
    }

    private func countdownBody(for target: CountdownTarget, daysBefore: Int) -> String {
        if let bodyTemplate = target.bodyTemplate, !bodyTemplate.isEmpty {
            return bodyTemplate
                .replacingOccurrences(of: "{days}", with: "\(daysBefore)")
                .replacingOccurrences(of: "{title}", with: target.title)
        }

        if daysBefore == 0 {
            return "\(target.title) is today."
        }

        if daysBefore == 1 {
            return "1 day left until \(target.title)."
        }

        return "\(daysBefore) days left until \(target.title)."
    }

    private func buildSettings(from config: [String: Any]) -> ScheduleSettings {
        let inactivityDays = intValue(for: ["last_open_notification_days",
                                            "inactive_notification_days",
                                            "notification_inactive_days"],
                                      in: config) ?? defaultInactivityDays

        let countdownDays = intArrayValue(for: ["countdown_notification_days",
                                                "notification_countdown_days"],
                                          in: config) ?? defaultCountdownDays
        let debugInactivityDelaySeconds = intValue(for: ["debug_inactivity_delay_seconds"], in: config)
        let debugCountdownDelaySeconds = intValue(for: ["debug_countdown_delay_seconds"], in: config)

        let targets = [
            countdownTarget(in: config,
                            identifier: "date1",
                            titleKeys: ["notification_date_1_title", "countdown_date_1_title"],
                            bodyKeys: ["notification_date_1_body", "countdown_date_1_body"],
                            dateKeys: ["notification_date_1", "countdown_date_1"]),
            countdownTarget(in: config,
                            identifier: "date2",
                            titleKeys: ["notification_date_2_title", "countdown_date_2_title"],
                            bodyKeys: ["notification_date_2_body", "countdown_date_2_body"],
                            dateKeys: ["notification_date_2", "countdown_date_2"])
        ].compactMap { $0 }

        let isEnabled = boolValue(for: ["notification_enabled", "notifications_enabled"], in: config) ?? true

        return ScheduleSettings(isEnabled: isEnabled,
                                inactivityDays: inactivityDays,
                                countdownDays: countdownDays,
                                targets: targets,
                                debugInactivityDelaySeconds: debugInactivityDelaySeconds,
                                debugCountdownDelaySeconds: debugCountdownDelaySeconds)
    }

    private func countdownTarget(in config: [String: Any],
                                 identifier: String,
                                 titleKeys: [String],
                                 bodyKeys: [String],
                                 dateKeys: [String]) -> CountdownTarget? {
        guard let isoDate = stringValue(for: dateKeys, in: config),
              parseDate(isoDate) != nil else {
            return nil
        }

        let title = stringValue(for: titleKeys, in: config) ?? "Upcoming exam"
        let body = stringValue(for: bodyKeys, in: config)
        return CountdownTarget(identifier: identifier, title: title, bodyTemplate: body, isoDate: isoDate)
    }

    private func normalizedNotificationDate(from date: Date) -> Date {
        if let normalizedDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) {
            return normalizedDate
        }

        return date
    }

    private func clampedReminderDate(from date: Date) -> Date {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        let clampedHour = min(max(hour, minimumReminderHour), maximumReminderHour)
        let clampedMinute = clampedHour == maximumReminderHour && hour > maximumReminderHour ? 0 : minute

        if let adjustedDate = calendar.date(bySettingHour: clampedHour, minute: clampedMinute, second: 0, of: date) {
            return adjustedDate
        }

        return date
    }

    private func countdownIdentifier(for identifier: String, daysBefore: Int) -> String {
        return "cbed.notification.countdown.\(identifier).\(daysBefore)"
    }

    private func parseDate(_ value: String) -> Date? {
        let formatters = [
            DateFormatter.iso8601Full,
            NotificationScheduler.makeFormatter("yyyy-MM-dd'T'HH:mm:ssZ"),
            NotificationScheduler.makeFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSZ"),
            NotificationScheduler.makeFormatter("yyyy-MM-dd")
        ]

        for formatter in formatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return ISO8601DateFormatter().date(from: value)
    }

    private func stringValue(for keys: [String], in config: [String: Any]) -> String? {
        for key in keys {
            if let value = config[key] as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return nil
    }

    private func intValue(for keys: [String], in config: [String: Any]) -> Int? {
        for key in keys {
            switch config[key] {
            case let value as Int:
                return value
            case let value as NSNumber:
                return value.intValue
            case let value as String:
                if let intValue = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return intValue
                }
            default:
                continue
            }
        }

        return nil
    }

    private func intArrayValue(for keys: [String], in config: [String: Any]) -> [Int]? {
        for key in keys {
            if let values = config[key] as? [Int] {
                return values
            }

            if let values = config[key] as? [NSNumber] {
                return values.map(\.intValue)
            }

            if let value = config[key] as? String {
                let parsedValues = value
                    .split(separator: ",")
                    .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

                if !parsedValues.isEmpty {
                    return parsedValues
                }
            }
        }

        return nil
    }

    private func boolValue(for keys: [String], in config: [String: Any]) -> Bool? {
        for key in keys {
            switch config[key] {
            case let value as Bool:
                return value
            case let value as NSNumber:
                return value.boolValue
            case let value as String:
                switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
                case "true", "1", "yes", "y":
                    return true
                case "false", "0", "no", "n":
                    return false
                default:
                    continue
                }
            default:
                continue
            }
        }

        return nil
    }

    private static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }
}
