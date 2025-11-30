// MARK: - Reducer.swift
// InnoFlow - A Hybrid Architecture Framework for SwiftUI
// Copyright © 2025 InnoSquad. All rights reserved.

import Foundation

/// A protocol that defines the core structure of a feature in InnoFlow.
///
/// The Reducer protocol establishes the unidirectional data flow pattern:
/// `Action → reduce() → Mutations + Effects → mutate() → State → View`
///
/// ## Example
/// ```swift
/// @Reducer
/// struct CounterFeature {
///     struct State: Equatable {
///         var count = 0
///     }
///
///     enum Action {
///         case increment
///         case decrement
///     }
///
///     enum Mutation {
///         case setCount(Int)
///     }
///
///     enum Effect {
///         // No effects for this simple feature
///     }
///
///     func reduce(state: State, action: Action) -> Reduce<Mutation, Effect> {
///         switch action {
///         case .increment:
///             return .mutations([.setCount(state.count + 1)])
///         case .decrement:
///             return .mutations([.setCount(state.count - 1)])
///         }
///     }
///
///     func mutate(state: inout State, mutation: Mutation) {
///         switch mutation {
///         case .setCount(let value):
///             state.count = value
///         }
///     }
///
///     func handle(effect: Effect) async -> EffectOutput<Action> {
///         // No effects to handle
///     }
/// }
/// ```
public protocol Reducer<State, Action, Mutation, Effect> {
    
    /// The state managed by this reducer.
    associatedtype State: Equatable
    
    /// The actions that can be sent to this reducer.
    associatedtype Action: Sendable
    
    /// The mutations that modify the state.
    associatedtype Mutation
    
    /// The side effects that this reducer can trigger.
    associatedtype Effect: Sendable
    
    /// Determines what mutations and effects should occur in response to an action.
    ///
    /// This is a pure function that takes the current state and an action,
    /// and returns the mutations to apply and effects to execute.
    ///
    /// - Parameters:
    ///   - state: The current state (read-only).
    ///   - action: The action to process.
    /// - Returns: A `Reduce` containing mutations and effects.
    func reduce(state: State, action: Action) -> Reduce<Mutation, Effect>
    
    /// Applies a mutation to the state.
    ///
    /// This function directly modifies the state based on the mutation.
    /// It should be a pure, synchronous operation.
    ///
    /// - Parameters:
    ///   - state: The state to modify.
    ///   - mutation: The mutation to apply.
    func mutate(state: inout State, mutation: Mutation)
    
    /// Handles a side effect and returns resulting action(s).
    ///
    /// This is where async operations like network requests,
    /// database access, or other side effects are performed.
    ///
    /// - Parameter effect: The effect to handle.
    /// - Returns: An `EffectOutput` containing zero, one, or multiple actions.
    func handle(effect: Effect) async -> EffectOutput<Action>
}

// MARK: - Default Implementation for Empty Effects

public extension Reducer where Effect == Never {
    func handle(effect: Effect) async -> EffectOutput<Action> {
        // Never type cannot be instantiated, so this is unreachable
    }
}
