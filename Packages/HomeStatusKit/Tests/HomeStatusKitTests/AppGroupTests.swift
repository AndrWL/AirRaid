//
//  AppGroupTests.swift
//  HomeStatusKitTests
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Testing
@testable import HomeStatusKit

@Suite("AppGroup")
struct AppGroupTests {

    @Test
    func identifier_whenApp_thenPrefixesBundleIdentifier() {
        let identifier = AppGroup.identifier(bundleIdentifier: "com.andriilebediev.airraid.dev", isExtension: false)

        #expect(identifier == "group.com.andriilebediev.airraid.dev")
    }

    @Test
    func identifier_whenExtension_thenUsesEmbeddingAppIdentifier() {
        let identifier = AppGroup.identifier(bundleIdentifier: "com.andriilebediev.airraid.dev.widgets", isExtension: true)

        #expect(identifier == "group.com.andriilebediev.airraid.dev")
    }
}
