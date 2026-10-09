import Foundation

struct EpisodeIndex: Codable {
    var updated: String?
    var episodes: [EpisodeSummary]
}

struct EpisodeSummary: Codable, Identifiable, Hashable {
    var date: String
    var title: String
    var summary: String
    var durationSeconds: Int
    var file: String

    var id: String { date }
}

struct Episode: Codable, Identifiable {
    var date: String
    var title: String
    var summary: String
    var durationSeconds: Int
    var segments: [Segment]

    var id: String { date }
}

struct Segment: Codable, Hashable {
    var kind: String
    var headline: String
    var text: String
    var source: String?
    var url: String?

    var isNews: Bool { kind == "news" }
}

enum Format {
    private static let parser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Amsterdam")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func dutch(_ pattern: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nl_NL")
        formatter.timeZone = TimeZone(identifier: "Europe/Amsterdam")
        formatter.dateFormat = pattern
        return formatter
    }

    private static let longFormatter = dutch("EEEE d MMMM")
    private static let shortFormatter = dutch("d MMM")
    private static let weekdayFormatter = dutch("EEEE")

    /// "vrijdag 9 oktober"
    static func longDate(_ iso: String) -> String {
        guard let date = parser.date(from: iso) else { return iso }
        return longFormatter.string(from: date)
    }

    /// "9 okt"
    static func shortDate(_ iso: String) -> String {
        guard let date = parser.date(from: iso) else { return iso }
        return shortFormatter.string(from: date).replacingOccurrences(of: ".", with: "")
    }

    /// "vrijdag"
    static func weekday(_ iso: String) -> String {
        guard let date = parser.date(from: iso) else { return "" }
        return weekdayFormatter.string(from: date)
    }

    static func isToday(_ iso: String) -> Bool {
        guard let date = parser.date(from: iso) else { return false }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Amsterdam") ?? .current
        return calendar.isDateInToday(date)
    }

    /// "4:36"
    static func clock(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// "5 min"
    static func minutes(_ seconds: Int) -> String {
        "\(max(1, Int((Double(seconds) / 60).rounded()))) min"
    }
}
