//
//  ThreadSafetyTests.swift
//  DependencyContainerTests
//

import Testing
@testable import DependencyContainer

/// Tests for thread safety of ``DefaultDependencyContainer``.
///
/// Serialized to avoid interference between concurrent test scenarios.
///
/// Covers:
/// - 100 concurrent singleton resolves return the same instance.
/// - Simultaneous registration and resolution does not cause data races or crashes.
@Suite(.serialized)
struct ThreadSafetyTests {

    // MARK: - Tests

    @Test
    func resolve_whenConcurrentSingleton_returnsSameInstance() async {
        let sut = makeSUT()
        sut.register(ServiceProtocol.self, lifetime: .singleton) { _ in
            ServiceImpl()
        }

        let results = await withTaskGroup(of: ServiceProtocol.self, returning: [ServiceProtocol].self) { group in
            for _ in 0..<100 {
                group.addTask {
                    sut.resolve(ServiceProtocol.self)
                }
            }
            
            var collected: [ServiceProtocol] = []
            
            for await result in group {
                collected.append(result)
            }
            
            return collected
        }
        
        for instance in results {
            #expect(results.first === instance)
        }
    }

    @Test
    func resolve_whenConcurrentRegisterAndResolve_doesNotCrash() async {
        let sut = makeSUT()
        sut.register(ServiceProtocol.self, lifetime: .transient) { _ in
            ServiceImpl()
        }

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                if i.isMultiple(of: 2) {
                    group.addTask {
                        sut.register(ServiceProtocol.self, lifetime: .transient) { _ in
                            ServiceImpl(id: "\(i)")
                        }
                    }
                } else {
                    group.addTask {
                        _ = sut.resolve(ServiceProtocol.self)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers

    private func makeSUT() -> DefaultDependencyContainer {
        DefaultDependencyContainer()
    }
}
