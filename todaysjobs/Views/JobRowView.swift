import SwiftUI

/// One row in Today's Jobs. Covers every state in the design:
/// pending, in progress, completed, overdue, missing customer name, missing address.
struct JobRowView: View {
    let job: Job
    let now: Date

    private var status: DisplayStatus { DisplayStatus(job: job, now: now) }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                customerName
                address
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                time
                StatusPill(status: status)
            }
        }
        .padding(.vertical, 12)
        .frame(minHeight: 72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // 17 pt semibold, primary. Null name -> "Unknown customer", secondary, regular.
    @ViewBuilder private var customerName: some View {
        if let name = job.displayCustomerName {
            Text(name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        } else {
            Text("Unknown customer")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // 15 pt regular, secondary, one line. Empty -> crossed-out pin + "No address yet".
    private var address: some View {
        Label {
            Text(job.displayAddress ?? "No address yet")
                .lineLimit(1)
                .truncationMode(.tail)
        } icon: {
            Image(systemName: job.displayAddress == nil ? "mappin.slash" : "mappin")
                .imageScale(.small)
        }
        .labelStyle(.compact)
        .font(.system(size: 15))
        .foregroundStyle(.secondary)
    }

    // 15 pt medium, monospaced digits. Overdue: red semibold. Completed: secondary.
    private var time: some View {
        Text(Self.timeFormatter.string(from: job.scheduledAt))
            .font(.system(size: 15, weight: status == .overdue ? .semibold : .medium))
            .monospacedDigit()
            .foregroundStyle(timeColor)
    }

    private var timeColor: Color {
        switch status {
        case .overdue: .red
        case .completed: .secondary
        default: .primary
        }
    }

    private var accessibilityText: String {
        let name = job.displayCustomerName ?? "Unknown customer"
        let place = job.displayAddress ?? "No address yet"
        let when = job.scheduledAt.formatted(date: .omitted, time: .shortened)
        return "\(name), \(place), \(when), \(status.title)"
    }

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

/// Icon + title with a tight gap, so the pin sits right next to the address.
private struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

private extension LabelStyle where Self == CompactLabelStyle {
    static var compact: CompactLabelStyle { CompactLabelStyle() }
}
