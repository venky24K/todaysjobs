# Today's Jobs

A small SwiftUI app that shows a field technician the jobs assigned to them for the day. They can open a job, see everything about it, and mark it as completed.

Built for the Zuper iOS Intern Assignment, Round 1.

## Running it

- Open `todaysjobs.xcodeproj` in Xcode 26.
- Choose an iPhone simulator and press **⌘R**.
- Press **⌘U** to run the unit tests.

Requirements: Swift and SwiftUI, iOS 17.0 or later, no third-party libraries.

## TestFlight

The app is available for **internal testing on TestFlight**.

- Build: version 1.0 (1), bundle ID `com.venkateshkonnipati.todaysjobs`
- Uploaded to App Store Connect with Transporter from a Release archive
- Internal testers need to be added to the app in App Store Connect. Ask for an invite, then install the build from the TestFlight app on an iPhone running iOS 17 or later.

## Features

### Required

- [x] Loads all 5 jobs from the bundled `jobs.json`, which is used exactly as given.
- [x] A list showing customer name, address, scheduled time and status, matching the design. All six row states are covered: pending, in progress, completed, overdue, missing customer name and missing address.
- [x] A detail screen showing all of a job's information, including notes.
- [x] **Mark as Completed** on the detail screen. The list and the "N pending" count update straight away.
- [x] An **All / Pending** switch to show only pending jobs.

### Bonus

- [x] Jobs are sorted by scheduled time.
- [x] Completed status survives an app restart.
- [x] Search by customer name or address. It ignores case and accents and works together with the All / Pending switch.
- [x] Unit tests for decoding the JSON, plus tests for the store. 18 tests in total, written with Swift Testing.
- [x] Empty and error states:
  - "No pending jobs" with a **Show All Jobs** button
  - "No results" for a search with no matches
  - "Couldn't load jobs" with **Try Again** if `jobs.json` is missing or invalid, instead of a crash

## Detail screen design

The detail screen is built for a technician standing at a customer's door. It's a native inset grouped list, following the iOS Human Interface Guidelines. From top to bottom:

1. **Who:** the customer name, or "Unknown customer", and the status pill.
2. **When:** the scheduled time and date. If the job is overdue, a red line says how late it is.
3. **Where:** the full address, which can be selected and copied, and **Get Directions**, which opens Apple Maps. If there's no address, it shows "No address yet" and a hint to check with the office.
4. **Notes:** shown in full, or "No notes for this job." when they're missing or empty.
5. **Job ID**, for talking to the office.

**Mark as Completed** is a large button pinned to the bottom of the screen, so it's easy to reach with a thumb. It gives a success haptic. After completing, an **Undo** link restores the job's original status, in case of a mis-tap.

## Handling the JSON as given

| In the data | How it's handled |
|---|---|
| `customer_name: null` (J-103) | Decoded as optional. Shown as "Unknown customer" in the secondary colour at regular weight. |
| `address: ""` (J-105) | Shown as "No address yet" with a crossed-out pin. Get Directions is hidden. |
| `notes` key missing (J-102) or `""` (J-103) | Decoded as optional. Shown as "No notes for this job." |
| `status: "in_progress"` | Mapped to an enum case and displayed as "In progress". |
| `scheduled_at: "2026-11-25 09:30"` | Parsed with a fixed `yyyy-MM-dd HH:mm` formatter (`en_US_POSIX`), in the device's local time zone. |
| Bad date or unknown status | Decoding throws an error. The app shows the error state instead of crashing. |

## Assumptions

- **"Pending" means `status == "pending"`**, which includes overdue jobs. In-progress jobs aren't counted. This matches the "3 pending" count in the design for this data.
- **Overdue** is computed, not stored. It means a pending job whose scheduled time is before now. The list refreshes every minute so jobs turn overdue on time.
- **Times have no time zone** in the JSON, so they're read as the device's local time.
- **The header date** ("Wednesday, 25 November") is today's date on the device.
- **Saving completed jobs:** `jobs.json` is read-only in the app bundle, so the IDs of jobs completed in the app are saved in `UserDefaults` and applied on top of the JSON at launch. Undo removes them again.

## Project structure

```
todaysjobs/
  jobs.json               sample data, unchanged
  Models/Job.swift        Job model, decoding, display helpers, JSON loader
  Store/JobStore.swift    shared state: load, sort, mark completed, undo, saving
  Views/JobListView.swift list screen, All / Pending switch, search, empty and error states
  Views/JobRowView.swift  one row, covering all six design states
  Views/StatusPill.swift  status pill and the overdue rule
  Views/JobDetailView.swift  detail screen
todaysjobsTests/
  JobDecodingTests.swift  decoding and store tests
```

## AI tools used

- **Claude Code** (desktop app), used for the whole build. The full session transcript is in [claude-code-session.md](claude-code-session.md), exported from the Claude Code desktop app.
  - Share link: _add link here_
