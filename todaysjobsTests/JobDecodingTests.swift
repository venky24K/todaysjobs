import Foundation
import Testing
@testable import todaysjobs

/// Decoding tests for jobs.json, including every rough edge in the sample data.
@MainActor
struct JobDecodingTests {

    private func decode(_ json: String) throws -> [Job] {
        try JobLoader.decode(Data(json.utf8))
    }

    private func localDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    // MARK: - The bundled file

    @Test func bundledFileDecodesAllFiveJobs() throws {
        let jobs = try JobLoader.loadFromBundle()
        #expect(jobs.map(\.id) == ["J-101", "J-102", "J-103", "J-104", "J-105"])
    }

    @Test func bundledFileHasEachStatus() throws {
        let statuses = try JobLoader.loadFromBundle().map(\.status)
        #expect(statuses == [.pending, .inProgress, .pending, .completed, .pending])
    }

    // MARK: - Rough edges

    @Test func nullCustomerNameDecodesAsNil() throws {
        let job = try #require(try decode("""
        [{"id":"J-103","customer_name":null,"address":"8 LB Road","scheduled_at":"2026-11-25 13:15","status":"pending","notes":""}]
        """).first)
        #expect(job.customerName == nil)
        #expect(job.displayCustomerName == nil)
    }

    @Test func emptyAddressHasNoDisplayAddress() throws {
        let job = try #require(try decode("""
        [{"id":"J-105","customer_name":"Meena Lakshmi","address":"","scheduled_at":"2026-11-25 17:30","status":"pending"}]
        """).first)
        #expect(job.address == "")
        #expect(job.displayAddress == nil)
    }

    @Test func missingNotesKeyDecodesAsNil() throws {
        let job = try #require(try decode("""
        [{"id":"J-102","customer_name":"Priya S","address":"45 Usman Road","scheduled_at":"2026-11-25 11:00","status":"in_progress"}]
        """).first)
        #expect(job.notes == nil)
        #expect(job.displayNotes == nil)
    }

    @Test func emptyNotesHaveNoDisplayNotes() throws {
        let job = try #require(try decode("""
        [{"id":"J-103","customer_name":null,"address":"8 LB Road","scheduled_at":"2026-11-25 13:15","status":"pending","notes":""}]
        """).first)
        #expect(job.notes == "")
        #expect(job.displayNotes == nil)
    }

    @Test func inProgressStatusDecodesAndDisplaysNicely() throws {
        let job = try #require(try decode("""
        [{"id":"J-102","customer_name":"Priya S","address":"45 Usman Road","scheduled_at":"2026-11-25 11:00","status":"in_progress"}]
        """).first)
        #expect(job.status == .inProgress)
        #expect(job.status.displayName == "In progress")
    }

    @Test func scheduledAtIsReadAsLocalTime() throws {
        let job = try #require(try decode("""
        [{"id":"J-101","customer_name":"Ravi Kumar","address":"12 2nd Avenue","scheduled_at":"2026-11-25 09:30","status":"pending"}]
        """).first)
        #expect(job.scheduledAt == localDate(2026, 11, 25, 9, 30))
    }

    // MARK: - Bad data fails cleanly instead of crashing

    @Test func badDateFormatThrows() {
        #expect(throws: DecodingError.self) {
            try decode("""
            [{"id":"J-1","customer_name":"A","address":"B","scheduled_at":"25/11/2026 9:30","status":"pending"}]
            """)
        }
    }

    @Test func unknownStatusThrows() {
        #expect(throws: DecodingError.self) {
            try decode("""
            [{"id":"J-1","customer_name":"A","address":"B","scheduled_at":"2026-11-25 09:30","status":"cancelled"}]
            """)
        }
    }

    // MARK: - Overdue

    @Test func pendingJobPastItsTimeIsOverdue() throws {
        let job = try #require(try JobLoader.loadFromBundle().first { $0.id == "J-101" })
        #expect(job.isOverdue(at: localDate(2026, 11, 25, 9, 31)))
        #expect(!job.isOverdue(at: localDate(2026, 11, 25, 9, 29)))
    }

    @Test func completedJobIsNeverOverdue() throws {
        let job = try #require(try JobLoader.loadFromBundle().first { $0.id == "J-104" })
        #expect(!job.isOverdue(at: localDate(2026, 11, 26, 0, 0)))
    }
}

/// Store behaviour: mark completed, undo, and saving across restarts.
@MainActor
struct JobStoreTests {

    /// A fresh, empty UserDefaults so tests don't touch the app's real saved data.
    private func makeDefaults() -> UserDefaults {
        let name = "JobStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func jobsAreSortedByScheduledTime() {
        let store = JobStore(defaults: makeDefaults())
        let times = store.jobs.map(\.scheduledAt)
        #expect(times == times.sorted())
    }

    @Test func markCompletedUpdatesStatusAndPendingCount() {
        let store = JobStore(defaults: makeDefaults())
        #expect(store.pendingCount == 3)
        store.markCompleted("J-101")
        #expect(store.job(withID: "J-101")?.status == .completed)
        #expect(store.pendingCount == 2)
    }

    @Test func undoRestoresOriginalStatus() {
        let store = JobStore(defaults: makeDefaults())
        store.markCompleted("J-102")
        #expect(store.canReopen("J-102"))
        store.reopen("J-102")
        #expect(store.job(withID: "J-102")?.status == .inProgress)
    }

    @Test func jobCompletedInJSONCannotBeReopened() {
        let store = JobStore(defaults: makeDefaults())
        #expect(!store.canReopen("J-104"))
    }

    @Test func completedStatusSurvivesRestart() {
        let defaults = makeDefaults()
        JobStore(defaults: defaults).markCompleted("J-105")

        let relaunched = JobStore(defaults: defaults)
        #expect(relaunched.job(withID: "J-105")?.status == .completed)
        #expect(relaunched.pendingCount == 2)
    }

    @Test func loadFailureShowsErrorInsteadOfCrashing() {
        struct Broken: Error {}
        let store = JobStore(defaults: makeDefaults(), loader: { throw Broken() })
        #expect(store.jobs.isEmpty)
        #expect(store.loadError != nil)
    }
}
