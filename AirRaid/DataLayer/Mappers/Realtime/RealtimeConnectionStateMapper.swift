//
//  RealtimeConnectionStateMapper.swift
//  AirRaid
//
//  Created by ANDRII LEBEDIEV on 06.10.2026.
//

import WebSocketClient

/// Maps transport connection states to the domain ``RealtimeConnectionState``.
enum RealtimeConnectionStateMapper {

    static func map(_ state: WebSocketConnectionState) -> RealtimeConnectionState {
        switch state {
        case .disconnected:
            return .disconnected
        case .connecting, .reconnecting:
            return .connecting
        case .connected:
            return .connected
        case .waitingForNetwork:
            return .waitingForNetwork
        }
    }
}
