//
//  TestError.swift
//  WebSocketClientTests
//

/// The single error type thrown by test doubles.
enum TestError: Error, Equatable {
    case cancelled
    case connectionReset
    case headersUnavailable
}
