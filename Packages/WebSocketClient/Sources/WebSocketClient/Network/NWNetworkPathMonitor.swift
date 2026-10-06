//
//  NWNetworkPathMonitor.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import Foundation
import Network

/// Default ``NetworkPathMonitoring`` backed by `NWPathMonitor`.
///
/// Each call to ``pathUpdates()`` starts its own monitor, because an `NWPathMonitor` cannot be restarted
/// after `cancel()`.
public struct NWNetworkPathMonitor {

    public init() { }
}

// MARK: - NetworkPathMonitoring

extension NWNetworkPathMonitor: NetworkPathMonitoring {

    public func pathUpdates() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { path in
                continuation.yield(path.status == .satisfied)
            }
            continuation.onTermination = { _ in
                monitor.cancel()
            }
            monitor.start(queue: DispatchQueue(label: Constants.queueLabel))
        }
    }
}

// MARK: - Constants

private enum Constants {
    static let queueLabel = "WebSocketClient.NWNetworkPathMonitor"
}
