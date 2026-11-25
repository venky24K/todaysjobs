import Foundation
import Observation

/// Holds today's jobs and is shared by the list and detail screens,
/// so a change made on one screen shows up on the other.
@Observable
final class JobStore {
    private(set) var jobs: [Job] = []
    private(set) var loadError: String?

    init(loader: () throws -> [Job] = { try JobLoader.loadFromBundle() }) {
        load(using: loader)
    }

    func load(using loader: () throws -> [Job] = { try JobLoader.loadFromBundle() }) {
        do {
            jobs = try loader().sorted { $0.scheduledAt < $1.scheduledAt }
            loadError = nil
        } catch {
            jobs = []
            loadError = error.localizedDescription
        }
    }

    func job(withID id: Job.ID) -> Job? {
        jobs.first { $0.id == id }
    }

    var pendingCount: Int {
        jobs.filter { $0.status == .pending }.count
    }
}
