//
//  HomeStatusStoreTests.swift
//  HomeStatusKitTests
//
//  Created by ANDRII LEBEDIEV on 13.10.2026.
//

import Foundation
import Testing
@testable import HomeStatusKit

@Suite("HomeStatusStore")
struct HomeStatusStoreTests {

    @Test
    func load_whenNothingSaved_thenReturnsNil() throws {
        let sut = makeSUT()

        #expect(try sut.load() == nil)
    }

    @Test
    func load_whenSnapshotSaved_thenReturnsIt() throws {
        let sut = makeSUT()
        let snapshot = makeSnapshot()

        try sut.save(snapshot)

        #expect(try sut.load() == snapshot)
    }

    @Test
    func save_whenNoContainer_thenThrowsContainerUnavailable() {
        let sut = HomeStatusStore(containerURL: nil)

        #expect(throws: HomeStatusStoreError.containerUnavailable) {
            try sut.save(makeSnapshot())
        }
    }

    @Test
    func encode_whenMiniMapPoint_thenWritesPair() throws {
        let data = try JSONEncoder().encode(MiniMapPoint(x: 0.25, y: 0.5))

        #expect(String(decoding: data, as: UTF8.self) == "[0.25,0.5]")
    }

    @Test
    func hasSameContent_whenOnlyUpdatedAtDiffers_thenTrue() {
        let snapshot = makeSnapshot()
        let later = HomeStatusSnapshot(updatedAt: snapshot.updatedAt.addingTimeInterval(60), home: snapshot.home)

        #expect(later.hasSameContent(as: snapshot))
    }
}

// MARK: - Helpers

private extension HomeStatusStoreTests {

    func makeSUT() -> HomeStatusStore {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return HomeStatusStore(containerURL: directory)
    }

    func makeSnapshot() -> HomeStatusSnapshot {
        HomeStatusSnapshot(
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000),
            home: HomeStatus(
                placeKind: .home,
                placeName: "Ірпінь",
                regionName: "Київська область",
                alert: HomeAlert(level: .red, startedAt: Date(timeIntervalSince1970: 1_799_999_000)),
                nearestThreat: NearThreat(
                    id: "t1",
                    title: "Шахед ×3",
                    shortTitle: "Шахед",
                    iconName: "threat-shahed",
                    distanceText: "14 км від дому",
                    shortDistanceText: "14 км",
                    arrivalAt: Date(timeIntervalSince1970: 1_800_000_300),
                    otherCount: 1
                ),
                radiusKm: 25,
                miniMap: MiniMap(
                    aspectRatio: 1.2,
                    areas: [MiniMapArea(rings: [[MiniMapPoint(x: 0, y: 0), MiniMapPoint(x: 1, y: 0), MiniMapPoint(x: 0, y: 1)]], fill: .red)],
                    home: MiniMapPoint(x: 0.4, y: 0.6)
                )
            )
        )
    }
}
