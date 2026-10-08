//
//  WebSocketNonRetryableError.swift
//  WebSocketClient
//
//  Created by ANDRII LEBEDIEV on 08.10.2026.
//

/// Marks an error thrown by ``WebSocketClientConfiguration/urlProvider`` or
/// ``WebSocketClientConfiguration/headersProvider`` that retrying cannot fix — a missing key, a malformed address.
///
/// The client reports it as a failure and ends in `disconnected`, like a non-retryable status code, instead of
/// retrying forever. Call `connect()` again once the configuration changes.
public protocol WebSocketNonRetryableError: Error {}
