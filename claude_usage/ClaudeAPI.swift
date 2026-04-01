import Foundation

struct UsageData {
    var sessionUtilization: Double?
    var sessionResetsAt: Date?
    var weeklyUtilization: Double?
    var weeklyResetsAt: Date?
    var weeklySonnetUtilization: Double?
    var weeklySonnetResetsAt: Date?
}

enum ClaudeAPIError: LocalizedError {
    case noOrganization
    case invalidResponse
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .noOrganization: return String(localized: "error.no.org")
        case .invalidResponse: return String(localized: "error.invalid.response")
        case .unauthorized: return String(localized: "error.unauthorized")
        }
    }
}

class ClaudeAPI {
    static let shared = ClaudeAPI()
    private let baseURL = "https://claude.ai/api"

    func fetchUsage() async throws -> UsageData {
        let orgId = try await fetchOrganizationId()
        return try await fetchUsageData(orgId: orgId)
    }

    private func makeRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.httpShouldHandleCookies = true
        return request
    }

    private func fetchOrganizationId() async throws -> String {
        let url = URL(string: "\(baseURL)/organizations")!
        let request = makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 403 || http.statusCode == 401 {
            throw ClaudeAPIError.unauthorized
        }

        struct Org: Codable {
            let uuid: String?
            let id: Int?
        }
        let orgs = try JSONDecoder().decode([Org].self, from: data)
        guard let org = orgs.first else {
            throw ClaudeAPIError.noOrganization
        }
        guard let id = org.uuid ?? org.id.map(String.init) else {
            throw ClaudeAPIError.noOrganization
        }
        return id
    }

    private func fetchUsageData(orgId: String) async throws -> UsageData {
        let url = URL(string: "\(baseURL)/organizations/\(orgId)/usage")!
        let request = makeRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 403 || http.statusCode == 401 {
            throw ClaudeAPIError.unauthorized
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClaudeAPIError.invalidResponse
        }

        // Validate that we got at least the main usage windows
        guard json["five_hour"] is [String: Any] || json["seven_day"] is [String: Any] else {
            throw ClaudeAPIError.invalidResponse
        }

        return UsageData(
            sessionUtilization: parseOptionalUtilization(from: json["five_hour"]),
            sessionResetsAt: parseResetDate(from: json["five_hour"]),
            weeklyUtilization: parseOptionalUtilization(from: json["seven_day"]),
            weeklyResetsAt: parseResetDate(from: json["seven_day"]),
            weeklySonnetUtilization: parseOptionalUtilization(from: json["seven_day_sonnet"]),
            weeklySonnetResetsAt: parseResetDate(from: json["seven_day_sonnet"])
        )
    }

    private func parseOptionalUtilization(from window: Any?) -> Double? {
        guard let dict = window as? [String: Any], let util = dict["utilization"] else { return nil }
        return normalizeUtilization(util)
    }

    private func normalizeUtilization(_ util: Any) -> Double {
        var value: Double = 0
        if let num = util as? Double { value = num }
        else if let num = util as? Int { value = Double(num) }
        else if let str = util as? String, let num = Double(str) { value = num }
        return value > 1 ? value / 100.0 : value
    }

    private func parseResetDate(from window: Any?) -> Date? {
        guard let dict = window as? [String: Any], let reset = dict["resets_at"] else { return nil }
        if let timestamp = reset as? Double { return Date(timeIntervalSince1970: timestamp) }
        if let timestamp = reset as? Int { return Date(timeIntervalSince1970: Double(timestamp)) }
        if let str = reset as? String {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return iso.date(from: str) ?? ISO8601DateFormatter().date(from: str)
        }
        return nil
    }
}
