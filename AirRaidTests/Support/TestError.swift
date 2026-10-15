//
//  TestError.swift
//  AirRaidTests
//

/// The errors test doubles throw.
enum TestError: Error, Equatable {

    /// A transport failure: no answer from the server.
    case offline

    /// A double was called for something the test did not expect.
    case unexpectedCall
}
