import SwiftUI

/// How a job's status is shown. "Overdue" isn't in the JSON: it's a pending job
/// whose scheduled time has passed.
enum DisplayStatus: Equatable {
    case pending, inProgress, completed, overdue

    init(job: Job, now: Date) {
        switch job.status {
        case .pending: self = job.isOverdue(at: now) ? .overdue : .pending
        case .inProgress: self = .inProgress
        case .completed: self = .completed
        }
    }

    var title: String {
        switch self {
        case .pending: "Pending"
        case .inProgress: "In progress"
        case .completed: "Completed"
        case .overdue: "Overdue"
        }
    }

    var color: Color {
        switch self {
        case .pending: .orange
        case .inProgress: .blue
        case .completed: .green
        case .overdue: .red
        }
    }
}

/// Capsule status label: 12 pt semibold, tinted background.
struct StatusPill: View {
    let status: DisplayStatus

    var body: some View {
        Text(status.title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.15), in: Capsule())
            .fixedSize()
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusPill(status: .pending)
        StatusPill(status: .inProgress)
        StatusPill(status: .completed)
        StatusPill(status: .overdue)
    }
}
