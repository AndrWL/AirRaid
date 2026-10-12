//
//  DIRepositoryContainer.swift
//  AirRaid
//
//  Created by Serhii Kopanitskyi on 21.04.2026.
//

import DependencyContainer

/// DI container for repository-layer dependencies.
///
/// Uses its own `DefaultDependencyContainer` instance internally.
/// Dependencies are registered in `assemble(with:)` and exposed through `DIRepositoryContaining` properties.
///
/// ## Registering a new repository
///
/// Repositories typically depend on services. Use `appContainer.services` to access them:
///
/// ```swift
/// func assemble(with appContainer: DIAppContaining) {
///     let services = appContainer.services
///
///     container.register(UserRepositoryProtocol.self, lifetime: .transient) { _ in
///         UserRepositoryImpl(networkClient: services.networkClient)
///     }
/// }
/// ```
///
/// Then expose it:
/// ```swift
/// var userRepository: UserRepositoryProtocol {
///     container.resolve(UserRepositoryProtocol.self)
/// }
/// ```
///
/// ## Lifetime guidelines
///
/// - `.transient` — most repositories (stateless, depend on shared singleton services).
/// - `.singleton` — only if the repository maintains its own cache or state.
final class DIRepositoryContainer {
    
    /// The underlying container that handles the actual registration and resolution of dependencies.
    private let container: DependencyContaining
    
    /// Initializes a new service dependency container.
    ///
    /// - Parameter container: The core container instance to use for dependency management.
    ///   Defaults to a new instance of ``DefaultDependencyContainer``.
    init(
        container: DependencyContaining = DefaultDependencyContainer()
    ) {
        self.container = container
    }
}

// MARK: - DIAssembling

extension DIRepositoryContainer: DIAssembling {

    func assemble(with appContainer: DIAppContaining) {
        registerRegionBoundaryRepository()
        registerDistrictBoundaryRepository()
        registerCityRepository()
        registerAirSituationRepository(with: appContainer)
        registerFavoriteRegionsRepository()
    }
}

// MARK: - DIRepositoryContaining

extension DIRepositoryContainer: DIRepositoryContaining {

    var regionBoundaryRepository: RegionBoundaryRepositoryProtocol {
        return container.resolve(RegionBoundaryRepositoryProtocol.self)
    }

    var districtBoundaryRepository: DistrictBoundaryRepositoryProtocol {
        return container.resolve(DistrictBoundaryRepositoryProtocol.self)
    }

    var cityRepository: CityRepositoryProtocol {
        return container.resolve(CityRepositoryProtocol.self)
    }

    var airSituationRepository: AirSituationRepositoryProtocol {
        return container.resolve(AirSituationRepositoryProtocol.self)
    }

    var favoriteRegionsRepository: FavoriteRegionsRepositoryProtocol {
        return container.resolve(FavoriteRegionsRepositoryProtocol.self)
    }
}

// MARK: - Configuration

private extension DIRepositoryContainer {

    /// A singleton: it keeps the decoded outlines for the map and the region sheets.
    func registerRegionBoundaryRepository() {
        container.register(RegionBoundaryRepositoryProtocol.self, lifetime: .singleton) { _ in
            RegionBoundaryRepository()
        }
    }

    func registerDistrictBoundaryRepository() {
        container.register(DistrictBoundaryRepositoryProtocol.self, lifetime: .transient) { _ in
            DistrictBoundaryRepository()
        }
    }

    func registerCityRepository() {
        container.register(CityRepositoryProtocol.self, lifetime: .transient) { _ in
            CityRepository()
        }
    }

    /// A singleton so every subscriber sees the same situation.
    func registerAirSituationRepository(with appContainer: DIAppContaining) {
        container.register(AirSituationRepositoryProtocol.self, lifetime: .singleton) { _ in
            RealtimeAirSituationRepository(
                realtimeService: appContainer.services.realtimeService,
                versionStore: appContainer.services.realtimeVersionStore
            )
        }
    }

    /// A singleton so the map and the region sheet see the same list as it changes.
    func registerFavoriteRegionsRepository() {
        container.register(FavoriteRegionsRepositoryProtocol.self, lifetime: .singleton) { _ in
            FavoriteRegionsRepository()
        }
    }

    /* Usage exemple
    func registerUserRepository(with appContainer: DIAppContaining) {
        container.register(UserRepositoryProtocol.self, lifetime: .transient) { _ in
            UserRepository(
                remoteDataSource: UserRemoteDataSource(
                    httpClient: <#T##any HTTPClient#>,
                    requestFactory: <#T##any UserRequestFactoryProtocol#>,
                    jsonDecoder: <#T##JSONDecoder#>
                ),
                storageProvider: appContainer.services.storageProvider
            )
        }
    }
     */
}
