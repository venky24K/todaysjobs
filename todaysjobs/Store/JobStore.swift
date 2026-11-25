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

    /// IDs of jobs the technician marked Completed in the app. Saved so they stay
    /// completed after a restart (jobs.json itself is read-only in the bundle).
    private var completedInApp: Set<Job.ID> {
        didSet { defaults.set(Array(completedInApp).sorted(), forKey: Self.completedKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults
    static let completedKey = "completedJobIDs"

    init(defaults: UserDefaults = .standard,
         loader: () throws -> [Job] = { try JobLoader.loadFromBundle() }) {
        self.defaults = defaults
        self.completedInApp = Set(defaults.stringArray(forKey: Self.completedKey) ?? [])
        load(using: loader)
    }

    func load(using loader: () throws -> [Job] = { try JobLoader.loadFromBundle() }) {
        do {
            var loaded = try loader().sorted { $0.scheduledAt < $1.scheduledAt }
            originalStatus = Dictionary(loaded.map { ($0.id, $0.status) }, uniquingKeysWith: { first, _ in first })
            for index in loaded.indices where completedInApp.contains(loaded[index].id) {
                loaded[index].status = .completed
            }
            jobs = loaded
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
        completedInApp.insert(id)
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
        completedInApp.remove(id)
    }

    var pendingCount: Int {
        jobs.filter { $0.status == .pending }.count
    }
}
