import SwiftUI

/// "Today's Jobs": inset grouped list of the technician's jobs for the day.
struct JobListView: View {
    @Environment(JobStore.self) private var store

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
                    ForEach(store.jobs) { job in
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
        }
    }

    // "Wednesday, 25 November · 3 pending"
    private func header(now: Date) -> some View {
        Text("\(Self.dayFormatter.string(from: now)) · \(store.pendingCount) pending")
            .font(.system(size: 15))
            .foregroundStyle(Color(.secondaryLabel))
            .textCase(nil)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
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
