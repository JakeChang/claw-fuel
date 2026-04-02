import Foundation

enum AppGroupConstants {
    static let groupID = "group.dev.jkone.claw-fuel"
    static let fileName = "usage.json"

    static var sharedFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent(fileName)
    }

    static func write(_ data: SharedUsageData) {
        guard let url = sharedFileURL else { return }
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: url, options: .atomic)
    }

    static func read() -> SharedUsageData? {
        guard let url = sharedFileURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SharedUsageData.self, from: data)
    }
}

struct SharedUsageData: Codable {
    let sessionUtilization: Double
    let weeklyUtilization: Double
    let weeklySonnetUtilization: Double?
    let sessionResetsAt: Date?
    let weeklyResetsAt: Date?
    let weeklySonnetResetsAt: Date?
    let lastUpdated: Date
    let isLoggedIn: Bool
}
