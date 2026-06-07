# Vessel Maintenance Dashboard
### iPad App — Installation & User Guide

---

## What It Is

A self-contained vessel maintenance log that runs as a full-screen app on your iPad. All data is stored locally on the device — no internet connection required after the first load, no accounts, no sync. One HTML file does everything.

---

## Installing on iPad

### Step 1 — Get the file onto your iPad

Choose any of these methods:

**AirDrop (easiest)**
1. On your Mac, right-click `maintenance_dashboard.html` → Share → AirDrop
2. Select your iPad from the AirDrop list
3. On the iPad, tap Accept — the file opens in Safari automatically

**Email**
1. Email the file to yourself as an attachment
2. On the iPad, open Mail → tap the attachment → tap the Share icon → Open in Safari

**iCloud Drive**
1. Copy the file to your iCloud Drive folder on your Mac
2. On the iPad, open the Files app → iCloud Drive → tap the file
3. Tap Share → Open in Safari

---

### Step 2 — Add to Home Screen

Once the file is open in Safari:

1. Tap the **Share button** (box with arrow pointing up) in the Safari toolbar
2. Scroll down and tap **Add to Home Screen**
3. The name will pre-fill as **Sunset Serenade** — edit if desired
4. Tap **Add** in the upper right

The app now appears on your home screen with a dedicated icon. Tap it to launch full-screen with no browser chrome, just like a native app.

> **Tip:** Portrait orientation works best. Landscape adapts but the layout is optimized for portrait.

---

### Step 3 — First Launch

On first open, the app loads with pre-populated seed data from the vessel's maintenance history. All data from that point forward is yours — the seed is only written once and will not overwrite anything you add.

---

## The Interface

### Header

| Element | What it shows |
|---|---|
| Vessel name (top left) | Configurable in Settings |
| **Port** (blue) | Current Port engine hours |
| **Gen** (orange) | Current Generator hours |
| **Stbd** (green) | Current Starboard engine hours |
| Date & time (top right) | Live clock, updates every second |
| ⚙ gear icon | Opens Settings |

Hours in the header reflect the highest value logged for each system, or a manually entered override via the Update Engine Hours button.

---

## Tabs

### Overview

The main status screen. Shows current engine hours at the top, then three collapsible sections organized by component category.

**Engine Hours row**
Displays Port, Generator, and Stbd hours as large metric cards. Updated automatically from log entries, or manually via the ⏱ Update Engine Hours button.

**⏱ Update Engine Hours**
Tap to enter current hours for Port Engine, Stbd Engine, and Generator without creating a maintenance log entry. Useful after a run to keep interval calculations current. Manual entries override log-derived values.

**Collapsible sections**

Each section header shows status dot badges (🟢 🟡 🔴) and a summary line so you can assess condition at a glance without expanding. Tap the header to collapse or expand.

| Section | What it contains |
|---|---|
| 🛢 Oil | Engine and generator oil change tracking |
| 💧 Fluids & Filters | Fuel filters, Racors, coolant, and similar consumables |
| ⚙️ Components | Everything else — impellers, belts, zincs, heat exchangers |

**Status color coding (interval-tracked items)**
- 🟢 Green — within interval, hours remaining
- 🟡 Amber — within 25% of interval (due soon)
- 🔴 Red — at or past interval (overdue)

**Non-interval items** (components without a configured interval) show last service date and action only.

---

### Log

Full maintenance history, sorted newest first.

**Filter pills** — tap any system pill (Port Engine, Stbd Engine, Generator, Engines, All) to filter the log to that system.

**+ Add Entry** — logs a new maintenance event. Fields:

| Field | Required | Notes |
|---|---|---|
| Date | ✅ | Format: M/D/YYYY — defaults to today |
| Engine Hours | — | Hours at time of service |
| System | ✅ | Port Engine, Stbd Engine, Generator, or Engines |
| Action | — | Replaced, Checked, Repaired, Inspected |
| Component | ✅ | e.g. Oil, Impeller, Fuel Filter |
| Part Number | — | e.g. WIX 33528 |
| Notes | — | Free text |

**Editing an entry** — tap ✎ on any row to open that entry prefilled for editing. All fields are editable.

**Deleting an entry** — tap ✕ on any row. A confirmation prompt appears before deletion.

---

### Intervals

Manages which components are tracked against a service interval. Each interval drives the progress bars and status colors on the Overview tab.

**Interval rows** display:
- Component name and system
- Configured interval in hours
- Hours remaining per engine (or overdue status)
- Last service date and hour reading
- Progress bar

**+ Add Interval** — creates a new service interval. Fields:

| Field | Required | Notes |
|---|---|---|
| System | ✅ | Engine (Port + Stbd together), Port only, Stbd only, Generator, or Engines |
| Component | ✅ | Must match the component name used in log entries exactly |
| Interval (hours) | ✅ | Number of engine hours between services |

> **Important:** Component names are case-insensitive but must match what you log. If you log "Fuel Filter" and set an interval for "fuel filter", they will match. If you log "Fuel filter" and set an interval for "Fuel Filters" (plural), they will not match.

**Editing an interval** — tap ✎ to open the edit form prefilled. You can change the system, component name, or interval value.

**Deleting an interval** — tap ✕ with confirmation. Deleting an interval removes the tracking only — log entries are not affected.

**Chart** — the bar chart at the bottom compares hours since last service against the configured interval for each tracked system/component pair, color-coded by status.

---

### Settings (⚙)

| Setting | Description |
|---|---|
| Boat Name | Updates the header vessel name, browser title, and home screen label |
| Vessel ID | Updates the sub-header descriptor (e.g. OA 423) |

Tap Save — changes apply immediately and persist across sessions.

---

## Data & Storage

All data is stored in **Safari's local storage** for this file. This means:

- Data persists across app closes, restarts, and reboots
- Data is tied to this device and this file — it does not sync elsewhere
- **If you clear Safari website data** in iPad Settings → Safari → Advanced → Website Data, the log will reset to the original seed data

### What is stored locally

| Data | Storage key |
|---|---|
| Maintenance log entries | `ss_log` |
| Service intervals | `ss_intervals` |
| Manual engine hours overrides | `ss_manual_hrs` |
| Settings (boat name, vessel ID) | `ss_config` |

### Backing up your data

To protect against data loss from a Safari clear or device reset:
- Periodically share or save the HTML file after Claude regenerates it with your latest entries baked in as seed data
- Or export a copy of your data by asking Claude to generate an updated version of the file incorporating all current entries

---

## Notes on Connectivity

The app requires an internet connection on first load only, to fetch:
- Google Fonts (Bebas Neue, DM Sans, DM Mono)
- Chart.js charting library (cdnjs.cloudflare.com)

After Safari caches these, the app runs fully offline. If you need a completely offline-capable version with all assets embedded, ask Claude to inline them into the HTML file.

---

## Quick Reference

| Action | Where |
|---|---|
| Log a maintenance event | Log tab → + Add Entry |
| Edit or delete a log entry | Log tab → ✎ or ✕ on the row |
| Update current engine hours | Overview tab → ⏱ Update Engine Hours |
| Add a service interval | Intervals tab → + Add Interval |
| Edit or delete an interval | Intervals tab → ✎ or ✕ on the row |
| Change boat name or vessel ID | ⚙ gear icon (upper right) |
| Collapse/expand overview sections | Tap the section header |

---

*Built with Claude · Anthropic*
