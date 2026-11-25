import SwiftUI

/// Everything a technician at the customer's door needs: who, when, where
/// (with directions), the notes, and one big button to finish the job.
struct JobDetailView: View {
    let jobID: Job.ID

    @Environment(JobStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var completedTrigger = false

    var body: some View {
        if let job = store.job(withID: jobID) {
            TimelineView(.everyMinute) { context in
                content(job: job, now: context.date)
            }
        } else {
            ContentUnavailableView("Job not found", systemImage: "questionmark.folder")
        }
    }

    private func content(job: Job, now: Date) -> some View {
        let status = DisplayStatus(job: job, now: now)

        return List {
            header(job: job, status: status)

            Section("Schedule") {
                LabeledContent("Time") {
                    Text(JobRowView.timeFormatter.string(from: job.scheduledAt))
                        .monospacedDigit()
                        .foregroundStyle(status == .overdue ? .red : .primary)
                        .fontWeight(status == .overdue ? .semibold : .regular)
                }
                LabeledContent("Date", value: job.scheduledAt.formatted(date: .abbreviated, time: .omitted))
                if status == .overdue {
                    Label("Running late. This job was due \(job.scheduledAt.formatted(.relative(presentation: .named))).",
                          systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }
            }

            addressSection(job: job)

            Section("Notes") {
                if let notes = job.displayNotes {
                    Text(notes)
                        .textSelection(.enabled)
                } else {
                    Text("No notes for this job.")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                LabeledContent("Job ID", value: job.id)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(job.id)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            completionBar(job: job)
        }
        .sensoryFeedback(.success, trigger: completedTrigger)
    }

    // MARK: - Sections

    private func header(job: Job, status: DisplayStatus) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                if let name = job.displayCustomerName {
                    Text(name)
                        .font(.title2.bold())
                } else {
                    Text("Unknown customer")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                StatusPill(status: status)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func addressSection(job: Job) -> some View {
        Section {
            if let address = job.displayAddress {
                Label(address, systemImage: "mappin")
                    .textSelection(.enabled)
                Button {
                    openDirections(to: address)
                } label: {
                    Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                }
            } else {
                Label("No address yet", systemImage: "mappin.slash")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Address")
        } footer: {
            if job.displayAddress == nil {
                Text("Check with the office before heading out.")
            }
        }
    }

    // MARK: - Completion

    @ViewBuilder
    private func completionBar(job: Job) -> some View {
        VStack(spacing: 8) {
            if job.status == .completed {
                Label("Job completed", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity, minHeight: 50)
                if store.canReopen(job.id) {
                    Button("Undo") {
                        withAnimation { store.reopen(job.id) }
                    }
                    .font(.subheadline)
                }
            } else {
                Button {
                    withAnimation { store.markCompleted(job.id) }
                    completedTrigger.toggle()
                } label: {
                    Label("Mark as Completed", systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 34)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func openDirections(to address: String) {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [URLQueryItem(name: "daddr", value: address)]
        if let url = components?.url { openURL(url) }
    }
}

#Preview {
    NavigationStack {
        JobDetailView(jobID: "J-101")
    }
    .environment(JobStore())
}
