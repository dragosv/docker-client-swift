import Foundation

extension Date {

    /// Some API results contain dates in a specific date format.
    /// Supports various Docker-style date formats with different fractional second precisions.
    /// - Parameter string: String of the date to parse.
    /// - Returns: Returns a `Date` instance if the string is in the correct format. Otherwise nil is returned.
    static func parseDockerDate(_ string: String) -> Date? {
        // Try ISO8601 first (handles most Docker date formats)
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601.date(from: string) {
            return date
        }

        // Try without fractional seconds
        iso8601.formatOptions = [.withInternetDateTime]
        if let date = iso8601.date(from: string) {
            return date
        }

        // Fallback: try the original specific format
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}
