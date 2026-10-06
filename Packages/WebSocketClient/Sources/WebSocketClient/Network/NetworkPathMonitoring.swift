//
//  NetworkPathMonitoring.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

/// Reports whether the device currently has a usable network path.
public protocol NetworkPathMonitoring: Sendable {

    /// A stream of availability values. The first value is the current status;
    /// cancelling iteration stops monitoring.
    func pathUpdates() -> AsyncStream<Bool>
}
