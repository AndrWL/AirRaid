# AirRaid

An iOS app that shows the air situation in Ukraine: official air raid alerts and the threats reported by monitoring
channels — drones, missiles, guided bombs, aircraft — on one map, with a live feed, home screen widgets and a Live
Activity.

> [!IMPORTANT]
> AirRaid is an information aid. It does not replace sirens or official alerts. Positions and forecasts are estimates
> built from public monitoring channels.

## Features

- **Map**
  - Oblasts and raions are filled when an air raid alert is on (red or yellow by level), with official data from alerts.in.ua.
  - Threat pins are rotated by course, with the track, the target and a short forecast between reports.
  - The camera can be focused on one oblast.
  - Base map styles: match system, dark, light and detailed.
- **My places**
  - The user's location, a home and, with Plus, more saved places, each with its own radius.
  - A threat inside a radius turns red, sounds a signal and shows a banner with the distance and the estimated arrival.
- **Feed**
  - The situation as a chat of bubbles, filtered to "My places" or all of Ukraine, with an optional voice feed.
  - A night report summarising the night.
- **Widgets and Live Activity**
  - The home's alert and the nearest threat on the home screen and the lock screen, and in the Dynamic Island.
  - A Siri / Shortcuts intent says the same without opening the app.
- **AirRaid Plus**
  - An optional subscription for convenience: more places, 90 days of history, feed filters, the night report, voice rules.
  - Alerts, threats, the feed and warnings near the home are always free.

The interface is in Ukrainian.

## Data

| Source | What | How |
|---|---|---|
| Nebo API (the project's own backend) | Threats from monitoring channels, official alerts, daily totals | WebSocket: a snapshot, then changes |
| [alerts.in.ua](https://alerts.in.ua) | Official air raid alerts | Relayed by the Nebo API |
| [OpenFreeMap](https://openfreemap.org) | Base map tiles and styles (OpenMapTiles, OpenStreetMap data) | Loaded by MapLibre at runtime |
| OCHA COD-AB | Oblast and raion outlines | Bundled in `AirRaid/Resources/Map/` |

The server address comes from a signed config (Ed25519) and is cached on the device. Devices authenticate with App
Attest, and the simulator uses a developer token.

## Requirements

- Xcode with the iOS 17 SDK or later; Swift 6 language mode
- iOS 17.0 or later
- Third-party dependency: [MapLibre Native](https://github.com/maplibre/maplibre-native), resolved by Swift Package Manager

## Getting started

1. Clone the repository and open `AirRaid.xcodeproj`.
2. Create the git-ignored secrets file from its template:

   ```bash
   cp AppSecrets.swift.example AirRaid/App/Configuration/AppSecrets.swift
   ```

   On the simulator, an empty `devKey` falls back to a limited unattested token. Fill it in only if you have a key
   for the development server.
3. Signing: the team and entitlements are in `Config/Signing.xcconfig`. To sign with your own team, copy the template
   and set `DEVELOPMENT_TEAM`:

   ```bash
   cp Signing.local.xcconfig.example Config/Signing.local.xcconfig
   ```

   A free Personal Team cannot sign App Attest. Point the app at `AirRaid/AirRaidPersonalTeam.entitlements` (App
   Group only) in that file; the device then uses an unattested token. Without the App Group the widgets show
   "no data".
4. Run the `AirRaid` scheme on a simulator or a device. To test Plus purchases locally, select
   `Config/AirRaidPlus.storekit` in the scheme's StoreKit configuration.

## Build and test

Pick any available iPhone simulator for the destination:

```bash
xcodebuild -project AirRaid.xcodeproj -scheme AirRaid -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

```bash
xcodebuild test -project AirRaid.xcodeproj -scheme AirRaid \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

The local packages have their own tests:

```bash
swift test --package-path Packages/WebSocketClient
```

```bash
swift test --package-path Packages/HomeStatusKit
```

CI (`.github/workflows/ios.yml`) builds the app and tests `WebSocketClient` on pushes to `main` and on pull requests.

## Architecture

Clean Architecture with SwiftUI and `@Observable`:

```
Presentation → Domain ← Data
                 ↑
               Core
```

| Folder | Contents |
|---|---|
| `AirRaid/DomainLayer` | Models and protocols; no SwiftUI or UIKit |
| `AirRaid/DataLayer` | Repositories, data sources, DTOs and mappers, services (WebSocket, auth, StoreKit, UserDefaults) |
| `AirRaid/PresentationLayer` | Feature modules (CoordinatorView, View, ViewModel, Router, Factory, Routes), the design system, navigation |
| `AirRaid/Core` | Base view model and router |
| `AirRaid/App` | Entry point, dependency injection containers, configuration, App Intents |
| `AirRaidWidgets` | Widget extension: home screen and lock screen widgets, the Live Activity |
| `AirRaidTests` | Unit tests (Swift Testing), mirroring the app's layers |

Local Swift packages:

- `Packages/DependencyContainer` is the DI container.
- `Packages/WebSocketClient` is a WebSocket client with reconnect and backoff, ping/pong and network monitoring.
- `Packages/HomeStatusKit` is the data contract between the app and the widget extension (App Group).

MapLibre is imported only in `PresentationLayer/Modules/Map/Subviews`; the rest of the app works with domain models.

Conventions:

- View models and routers run on the main actor; the project's default isolation is `MainActor`.
- Colours are asset catalog colorsets, spacing comes from design tokens, and the font is Manrope.
- Tests use Swift Testing with `what_when_then` names and `makeSUT`, with stubs instead of mocking frameworks.
- Code comments are in English.

## Attribution

Map data, base map tiles, artwork, fonts and libraries that require attribution are listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
