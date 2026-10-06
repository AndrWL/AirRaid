//
//  DependencyLifetime.swift
//  DependencyContainer
//
//  Created by Serhii Kopanitskyi on 21.04.2026.
//

/// Defines the lifetime strategy for a registered dependency.
///
/// The lifetime determines how often a new instance is created when the dependency is resolved.
public enum DependencyLifetime {
    
    /// A single shared instance is created on first resolve and reused for all subsequent resolves.
    case singleton
    
    /// A new instance is created every time the dependency is resolved.
    case transient
    
    /// A shared instance is created and held weakly. It is reused as long as another object
    /// holds a strong reference to it. Once deallocated, a new instance will be created.
    /// - Warning: Can only be used with reference types (classes).
    case weak
}
