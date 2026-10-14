# HomeStatusKit

The contract between the AirRaid app and its widget extension: what the home screen widgets and the Live Activity
show, already formatted, plus the App Group file the app writes it to. No geometry, no networking, no app logic —
the app computes everything and the extension only draws it.

- `HomeStatusSnapshot` — the widgets' data: the home, its alert, the nearest threat in its radius and a mini-map of
  its oblast. Written by the app as JSON to the App Group container (`HomeStatusStore`); the widget reads it.
- `HomeAlertActivityAttributes` — the Live Activity shown while the home is under an air raid alert.
- `AppGroup` — the shared container's identifier, derived from the bundle identifier, so the Debug and Release apps
  (`com.andriilebediev.airraid[.dev]`) and their extensions (`….widgets`) each pair up with their own group.

Tests: `swift test --package-path Packages/HomeStatusKit`
