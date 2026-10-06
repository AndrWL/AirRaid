//
//  DependencyKey.swift
//  DependencyContainer
//
//  Created by Serhii Kopanitskyi on 03.05.2026.
//

import Foundation

/// A unique identifier used to register and resolve dependencies within the container.
///
/// `DependencyKey` combines the type of the dependency with an optional name. This allows
/// the dependency injection container to support both standard type-based resolution and
/// named registrations (tags), enabling multiple distinct instances of the same type
/// to be stored and resolved independently.
struct DependencyKey: Hashable {
    
    /// The unique runtime identifier of the registered dependency's type.
    let type: ObjectIdentifier
    
    /// An optional string identifier used to distinguish between multiple dependencies of the exact same type.
    let name: String?
}
