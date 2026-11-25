import SwiftUI

/// The All / Pending switch under the title.
enum JobFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pending = "Pending"

    var id: Self { self }

    /// "Pending" means status == pending, which includes overdue jobs
    /// (matches the "N pending" count in the header).
    func includes(_ job: Job) -> Bool {
        switch self {
        case .all: true
        case .pending: job.status == .pending
        }
    }
}

/// "Today's Jobs": inset grouped list of the technician's jobs for the day.
struct JobListView: View {
    @Environment(JobStore.self) private var store
    @State private var filter: JobFilter = .all

    private var visibleJobs: [Job] {
        store.jobs.filter(filter.includes)
    }

    var body: some View {
        NavigationStack {
            // Re-render every minute so pending jobs flip to Overdue on time.
            TimelineView(.everyMinute) { context in
                content(now: context.date)
            }
            .navigationTitle("Today's Jobs")
            .navigationDestination(for: Job.ID.self) { id in
                JobDetailView(jobID: id)
            }
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if let error = store.loadError {
            ContentUnavailableView {
                Label("Couldn't load jobs", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button("Try Again") { store.load() }
            }
        } else {
            List {
                Section {
                    ForEach(visibleJobs) { job in
                        NavigationLink(value: job.id) {
                            JobRowView(job: job, now: now)
                        }
                        // Row owns its 12 pt vertical padding; 16 pt leading per spec.
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                } header: {
                    header(now: now)
                }
            }
            .listStyle(.insetGrouped)
            .animation(.default, value: filter)
            .overlay {
                if visibleJobs.isEmpty {
                    emptyState
                }
            }
        }
    }

    // "Wednesday, 25 November · 3 pending" + All / Pending
    private func header(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(Self.dayFormatter.string(from: now)) · \(store.pendingCount) pending")
                .font(.system(size: 15))
                .foregroundStyle(Color(.secondaryLabel))

            Picker("Show", selection: $filter) {
                ForEach(JobFilter.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.large)
        }
        .textCase(nil)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
    }

    @ViewBuilder
    private var emptyState: some View {
        switch filter {
        case .pending:
            ContentUnavailableView {
                Label("No pending jobs", systemImage: "checkmark.circle")
            } description: {
                Text("Everything waiting to start is done.")
            } actions: {
                Button("Show All Jobs") { filter = .all }
            }
        case .all:
            ContentUnavailableView("No jobs today", systemImage: "calendar",
                                   description: Text("Jobs assigned to you will show up here."))
        }
    }

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return formatter
    }()
}

#Preview {
    JobListView()
        .environment(JobStore())
}
