# iOS Widget Extension – Implementation Plan

## Overview

The Flutter app writes a **DailySnapshot** JSON to shared storage (App Group). The iOS widget extension reads this snapshot and renders a minimal UI **offline** using the last written payload. No heavy logic runs in the widget.

---

## 1. Files Needed (Xcode / iOS)

| Item | Purpose |
|------|--------|
| **Widget Extension target** | New target in Xcode: File → New → Target → Widget Extension. Name e.g. `SaplingWidget`. |
| **App Group capability** | Same group on **Runner** and **SaplingWidget**: e.g. `group.com.sapling.app`. Must match `HomeWidget.setAppGroupId()` in Flutter. |
| **Info.plist** (widget) | Standard for widget extension. |
| **SwiftUI view** | One view that reads UserDefaults(suiteName:) and displays snapshot fields. |

---

## 2. App Group Setup

1. **Apple Developer**: Create an App Group ID (e.g. `group.com.sapling.app`).
2. **Runner target**: Signing & Capabilities → + Capability → App Groups → add `group.com.sapling.app`.
3. **SaplingWidget target**: Same: add App Groups → same ID.
4. **Flutter**: `main.dart` calls `HomeWidget.setAppGroupId('group.com.sapling.app')` (already added).

---

## 3. How the Widget Reads the Snapshot

- Flutter writes via `HomeWidget.saveWidgetData<String>('sapling_daily_snapshot', json)`.
- `home_widget` stores this in **UserDefaults with the App Group suite**.
- In the widget extension (Swift/SwiftUI):

```swift
let suite = UserDefaults(suiteName: "group.com.sapling.app")
let jsonString = suite?.string(forKey: "sapling_daily_snapshot")
// Parse JSON and read: todayAllowance, behindAmount, primaryGoalProgress, treeStage, closeoutStatus, timestamp
```

- **Offline**: If the app has never run or no snapshot was written, `jsonString` is nil → show a placeholder (“Open Sapling” or “No data”).
- **Small payload**: Snapshot is one JSON object with 6 fields; no heavy computation in the widget.

---

## 4. Snapshot JSON Shape

```json
{
  "todayAllowance": 85.0,
  "behindAmount": 0.0,
  "primaryGoalProgress": null,
  "treeStage": "sapling",
  "closeoutStatus": "3 days streak · Within budget",
  "timestamp": "2025-06-15T12:00:00.000"
}
```

- `primaryGoalProgress`: `0.0..1.0` when in goal mode, else `null`.
- `treeStage`: `"seedling"` | `"sapling"` | `"tree"` (from streak).

---

## 5. Minimal Widget UI (SwiftUI)

- Use **WidgetKit** timeline provider that:
  - Reads the snapshot from UserDefaults(suiteName: "group.com.sapling.app").
  - Returns a single timeline entry with the snapshot data (or placeholder).
- **View**: e.g. small/medium layout:
  - Title: “Today’s allowance” + `formatCurrency(snapshot.todayAllowance)`.
  - Subtitle: `snapshot.closeoutStatus`.
  - Optional: `treeStage` as icon (seedling / sapling / tree) or label.
  - Optional: “Behind” if `behindAmount > 0`.
- **Tap**: `widgetURL` to open the app (e.g. `sapling://` or your app URL scheme).

---

## 6. Refresh Limits (iOS)

- WidgetKit controls when the widget is refreshed; Flutter calls `HomeWidget.updateWidget(iOSName: "SaplingWidget", ...)` to request an update.
- iOS may throttle updates. Snapshot is written on every meaningful event (expense, income, reconcile, mark-paid, plan change, app launch); the last written snapshot is always used so the widget renders correctly offline with the latest data the app had.

---

## 7. Checklist

- [ ] Create Widget Extension target in Xcode.
- [ ] Add App Group to Runner and SaplingWidget (`group.com.sapling.app` or your ID).
- [ ] Implement timeline provider that reads `sapling_daily_snapshot` from `UserDefaults(suiteName:)`.
- [ ] Implement SwiftUI view with placeholder when snapshot is nil.
- [ ] Set `widgetURL` to open the app.
- [ ] Ensure Flutter `main.dart` calls `HomeWidget.setAppGroupId()` with the same group ID.
