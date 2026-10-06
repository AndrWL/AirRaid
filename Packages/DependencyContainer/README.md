# DependencyContainer

A lightweight, thread-safe Dependency Injection container for Swift.

## Overview

DependencyContainer provides a simple mechanism for registering and resolving dependencies with support for different lifetime strategies and named registrations. It is designed to be minimal, easy to understand, and safe to use in concurrent environments.

## Architecture

```
DependencyContainer/
├── DependencyContainer/
│   ├── DependencyContaining.swift       — Public protocols (Resolving, Registering, Containing)
│   └── DefaultDependencyContainer.swift — Thread-safe container implementation
├── DependencyLifetime/
│   └── DependencyLifetime.swift         — Lifetime strategies (singleton, transient, weak)
├── DependencyProvider/
│   ├── DependencyProvider.swift          — Internal provider protocol
│   ├── SingletonProvider.swift           — Caches instance on first resolve
│   ├── TransientProvider.swift           — Creates new instance on every resolve
│   └── WeakProvider.swift               — Holds weak reference, recreates when deallocated
└── Models/
    └── DependencyKey.swift              — Composite key (type + optional name)
```

## Protocols

| Protocol | Purpose |
|---|---|
| `DependencyResolving` | Resolves registered dependencies. `Sendable` — safe to share across threads. |
| `DependencyRegistering` | Registers dependencies with a lifetime and factory closure. |
| `DependencyContaining` | Combines both protocols. Use during app configuration. |

Pass `DependencyResolving` to components that only need to **consume** dependencies.
Pass `DependencyContaining` only where registration is required (e.g., `AppConfigurator`).

## Lifetime Strategies

| Lifetime | Behavior |
|---|---|
| `.singleton` | Created once on first resolve, shared across all subsequent resolves. |
| `.transient` | A new instance is created on every resolve call. |
| `.weak` | Created on first resolve and held weakly. Reused while any strong reference exists; recreated after deallocation. **Classes only.** |

## Usage

### Registration

Register a **protocol** as the key and provide a **concrete implementation** in the factory closure.
This decouples consumers from specific implementations.

```swift
let container = DefaultDependencyContainer()

// Singleton — one instance for the entire app lifetime
container.register(NetworkClientProtocol.self, lifetime: .singleton) { _ in
    NetworkClientImpl(baseURL: "https://api.example.com")
}

// Transient — new instance each time, with dependencies resolved from the container
container.register(UserRepositoryProtocol.self, lifetime: .transient) { resolver in
    UserRepositoryImpl(
        networkClient: resolver.resolve(NetworkClientProtocol.self)
    )
}

// Weak — shared while alive, recreated after deallocation
container.register(SessionManager.self, lifetime: .weak) { _ in
    SessionManager()
}
```

### Named Registration

Register multiple implementations of the same type using a name to distinguish them:

```swift
// Register two different network clients
container.register(HTTPClient.self, name: "auth", lifetime: .singleton) { _ in
    NetworkClient(configuration: .default(errorMapper: AuthErrorMapper()))
}

container.register(HTTPClient.self, name: "api", lifetime: .singleton) { resolver in
    let authInterceptor = AuthenticationInterceptor(tokenProvider: resolver.resolve(AuthManager.self))
    return NetworkClient(configuration: .default(interceptors: [authInterceptor], errorMapper: AppErrorMapper()))
}

// Resolve by name
let authClient = container.resolve(HTTPClient.self, name: "auth")
let apiClient = container.resolve(HTTPClient.self, name: "api")
```

The default (unnamed) registration and resolution use `name: nil` under the hood, so existing code without names continues to work unchanged.

### Resolution

```swift
let networkClient = container.resolve(NetworkClientProtocol.self)
let userRepository = container.resolve(UserRepositoryProtocol.self)
```

### Passing resolver to other layers

Pass `DependencyResolving` (not the full container) to components that only need to consume dependencies:

```swift
class ProfileViewModel {
    private let fetchUserUseCase: FetchUserUseCase

    init(resolver: DependencyResolving) {
        self.fetchUserUseCase = FetchUserUseCase(
            repository: resolver.resolve(UserRepositoryProtocol.self)
        )
    }
}
```

## Thread Safety

`DefaultDependencyContainer` is `@unchecked Sendable` and uses `NSRecursiveLock` internally.
The recursive lock is required because a factory closure may resolve other dependencies during creation,
causing nested `resolve` calls on the same thread.

## Important Notes

- Resolving an unregistered dependency triggers a `fatalError` with a descriptive message.
- Registering the same type (and name) twice silently overwrites the previous registration.
- Providers (`SingletonProvider`, `TransientProvider`, `WeakProvider`) are internal and not accessible outside the module.
- Using `.weak` lifetime with value types (structs/enums) triggers a `fatalError` — only classes are supported.
