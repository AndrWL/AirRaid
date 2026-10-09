# WebSocketClient

Self-healing WebSocket transport on top of `URLSessionWebSocketTask`. Transport only — no endpoints,
message schemas, or app logic.

## Features

- **Reconnect** with exponential backoff and jitter (`ReconnectPolicy`); a successful connection resets the backoff
- **Heartbeat** — periodic ping; a missing pong within `pongTimeout` tears the connection down and reconnects
- **Handshake confirmation** — the first pong marks the connection `connected`, so `send` never races the upgrade
- **Network awareness** — `NWPathMonitor`: pauses in `waitingForNetwork`, reconnects immediately when the path returns
- **Auth headers** — `headersProvider` is called before every attempt, so refreshed tokens are picked up
- **Handshake errors** — non-101 upgrade responses surface as `.handshakeFailed(statusCode:)` (e.g. 401)
- **Close codes** — a close frame after the upgrade surfaces as `.closedByServer(code:reason:)` (e.g. `4401`) and is retried;
  `failureHandler` is awaited before the retry, so credentials the server rejected can be dropped first

## Usage

```swift
let client = WebSocketClient(
    configuration: WebSocketClientConfiguration(
        url: url,
        headersProvider: { ["Authorization": "Bearer \(try await tokenProvider.fetchToken())"] }
    )
)

Task {
    for await event in client.events {
        switch event {
        case .stateChanged(let state): ...
        case .message(let message): ...
        case .failure(let error): ...
        }
    }
}

await client.connect()
try await client.send(.text("{\"type\":\"subscribe\"}"))
await client.disconnect()
```

`events` is an `AsyncStream` — **single consumer**. Fan out in the one place that owns the client.

App lifecycle (background/foreground) is intentionally not handled here — the owner calls
`disconnect()` / `connect()`.

## Testing

```bash
swift test --package-path Packages/WebSocketClient
```

Transport, timers, and network path are injected (`WebSocketTaskFactoryProtocol`, `Sleeping`,
`NetworkPathMonitoring`), so the tests run in milliseconds with no server.
