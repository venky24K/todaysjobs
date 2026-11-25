import Foundation

/// The status values that appear in `jobs.json`.
enum JobStatus: String, Codable, Hashable {
    case pending
    case inProgress = "in_progress"
    case completed

    /// Text shown to the technician ("in_progress" reads as "In progress").
    var displayName: String {
        switch self {
        case .pending: "Pending"
        case .inProgress: "In progress"
        case .completed: "Completed"
        }
    }
}

/// One job from `jobs.json`.
///
/// The JSON is used exactly as given, so the model has to handle its rough edges:
/// - `customer_name` can be `null`
/// - `address` can be an empty string
/// - `notes` can be missing entirely, or an empty string
/// - `scheduled_at` is "yyyy-MM-dd HH:mm" with no time zone (read as the device's local time)
struct Job: Identifiable, Hashable, Codable {
    let id: String
    let customerName: String?
    let address: String
    let scheduledAt: Date
    var status: JobStatus
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case customerName = "customer_name"
        case address
        case scheduledAt = "scheduled_at"
        case status
        case notes
    }

    init(id: String, customerName: String?, address: String, scheduledAt: Date, status: JobStatus, notes: String?) {
        self.id = id
        self.customerName = customerName
        self.address = address
        self.scheduledAt = scheduledAt
        self.status = status
        self.notes = notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        customerName = try container.decodeIfPresent(String.self, forKey: .customerName)
        address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        status = try container.decode(JobStatus.self, forKey: .status)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)

        let rawDate = try container.decode(String.self, forKey: .scheduledAt)
        guard let date = Job.dateFormatter.date(from: rawDate) else {
            throw DecodingError.dataCorruptedError(
                forKey: .scheduledAt, in: container,
                debugDescription: "Expected \"yyyy-MM-dd HH:mm\", got \"\(rawDate)\""
            )
        }
        scheduledAt = date
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(customerName, forKey: .customerName)
        try container.encode(address, forKey: .address)
        try container.encode(Job.dateFormatter.string(from: scheduledAt), forKey: .scheduledAt)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(notes, forKey: .notes)
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}

// MARK: - Display helpers

extension Job {
    /// Customer name with blank/null handled, or nil when there isn't one.
    var displayCustomerName: String? {
        guard let name = customerName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return nil }
        return name
    }

    /// Address with blank handled, or nil when there isn't one.
    var displayAddress: String? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Notes with blank/missing handled, or nil when there aren't any.
    var displayNotes: String? {
        guard let notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty else { return nil }
        return notes
    }

    /// A pending job whose scheduled time has already passed.
    func isOverdue(at now: Date = .now) -> Bool {
        status == .pending && scheduledAt < now
    }
}

// MARK: - Loading

enum JobLoader {
    enum LoadError: LocalizedError {
        case fileMissing
        case unreadable(Error)

        var errorDescription: String? {
            switch self {
            case .fileMissing: "jobs.json wasn't found in the app bundle."
            case .unreadable(let error): "jobs.json couldn't be read: \(error.localizedDescription)"
            }
        }
    }

    static func decode(_ data: Data) throws -> [Job] {
        try JSONDecoder().decode([Job].self, from: data)
    }

    static func loadFromBundle(_ bundle: Bundle = .main, fileName: String = "jobs") throws -> [Job] {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw LoadError.fileMissing
        }
        do {
            return try decode(Data(contentsOf: url))
        } catch {
            throw LoadError.unreadable(error)
        }
    }
}
