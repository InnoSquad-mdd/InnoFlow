// MARK: - Reduce.swift
// InnoFlow - A Hybrid Architecture Framework for SwiftUI
// Copyright © 2025 InnoSquad. All rights reserved.

import Foundation

/// The result of processing an action in a reducer.
///
/// `Reduce` encapsulates both the mutations to apply to the state
/// and the effects to execute asynchronously.
///
/// ## Example
/// ```swift
/// func reduce(state: State, action: Action) -> Reduce<Mutation, Effect> {
///     switch action {
///     case .load:
///         return Reduce(
///             mutations: [.setLoading(true)],
///             effects: [.fetchData]
///         )
///     case .loaded(let data):
///         return .mutations([.setData(data), .setLoading(false)])
///     }
/// }
/// ```
public struct Reduce<Mutation, Effect> {
    
    /// The mutations to apply to the state.
    public let mutations: [Mutation]
    
    /// The effects to execute.
    public let effects: [Effect]
    
    /// Creates a new Reduce with the specified mutations and effects.
    ///
    /// - Parameters:
    ///   - mutations: The mutations to apply. Defaults to empty.
    ///   - effects: The effects to execute. Defaults to empty.
    public init(
        mutations: [Mutation] = [],
        effects: [Effect] = []
    ) {
        self.mutations = mutations
        self.effects = effects
    }
}

// MARK: - Convenience Initializers

public extension Reduce {
    
    /// Creates a Reduce with only mutations (no effects).
    ///
    /// - Parameter mutations: The mutations to apply.
    /// - Returns: A Reduce with the specified mutations and no effects.
    static func mutations(_ mutations: [Mutation]) -> Self {
        Reduce(mutations: mutations, effects: [])
    }
    
    /// Creates a Reduce with a single mutation (no effects).
    ///
    /// - Parameter mutation: The mutation to apply.
    /// - Returns: A Reduce with a single mutation and no effects.
    static func mutation(_ mutation: Mutation) -> Self {
        Reduce(mutations: [mutation], effects: [])
    }
    
    /// Creates a Reduce with only effects (no mutations).
    ///
    /// - Parameter effects: The effects to execute.
    /// - Returns: A Reduce with no mutations and the specified effects.
    static func effects(_ effects: [Effect]) -> Self {
        Reduce(mutations: [], effects: effects)
    }
    
    /// Creates a Reduce with a single effect (no mutations).
    ///
    /// - Parameter effect: The effect to execute.
    /// - Returns: A Reduce with no mutations and a single effect.
    static func effect(_ effect: Effect) -> Self {
        Reduce(mutations: [], effects: [effect])
    }
    
    /// Creates a Reduce with no mutations and no effects.
    ///
    /// Use this when an action doesn't require any state changes or side effects.
    static var none: Self {
        Reduce(mutations: [], effects: [])
    }
}

// MARK: - Sendable Conformance

extension Reduce: Sendable where Mutation: Sendable, Effect: Sendable {}

// MARK: - Equatable Conformance

extension Reduce: Equatable where Mutation: Equatable, Effect: Equatable {}
