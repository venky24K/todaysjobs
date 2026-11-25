import Foundation
import Observation

/// Holds today's jobs and is shared by the list and detail screens,
/// so a change made on one screen shows up on the other.
@Observable
final class JobStore {
    private(set) var jobs: [Job] = []
    private(set) var loadError: String?
    /// Status each job had in jobs.json, so a mistaken "Completed" can be undone.
    private var originalStatus: [Job.ID: JobStatus] = [:]

    init(loader: () throws -> [Job] = { try JobLoader.loadFromBundle() }) {
        load(using: loader)
    }

    func load(using loader: () throws -> [Job] = { try JobLoader.loadFromBundle() }) {
        do {
            jobs = try loader().sorted { $0.scheduledAt < $1.scheduledAt }
            originalStatus = Dictionary(uniqueKeysWithValues: jobs.map { ($0.id, $0.status) })
            loadError = nil
        } catch {
            jobs = []
            loadError = error.localizedDescription
        }
    }

    func job(withID id: Job.ID) -> Job? {
        jobs.first { $0.id == id }
    }

    func markCompleted(_ id: Job.ID) {
        guard let index = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[index].status = .completed
    }

    /// True when the job was completed in the app (not already completed in jobs.json).
    func canReopen(_ id: Job.ID) -> Bool {
        job(withID: id)?.status == .completed && originalStatus[id] != .completed
    }

    /// Undo "Mark as Completed": put the job back to the status it had in jobs.json.
    func reopen(_ id: Job.ID) {
        guard canReopen(id), let index = jobs.firstIndex(where: { $0.id == id }),
              let original = originalStatus[id] else { return }
        jobs[index].status = original
    }

    var pendingCount: Int {
        jobs.filter { $0.status == .pending }.count
    }
}
