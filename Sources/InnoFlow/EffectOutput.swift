// MARK: - EffectOutput.swift
// InnoFlow - A Hybrid Architecture Framework for SwiftUI
// Copyright © 2025 InnoSquad. All rights reserved.

import Foundation

/// The output of handling an effect.
///
/// `EffectOutput` represents the possible results of handling a side effect:
/// - `.none`: No action to dispatch (fire-and-forget)
/// - `.single`: A single action to dispatch
/// - `.stream`: Multiple actions dispatched over time
///
/// ## Example
/// ```swift
/// func handle(effect: Effect) async -> EffectOutput<Action> {
///     switch effect {
///     // Fire-and-forget (analytics, logging)
///     case .trackEvent(let name):
///         analytics.track(name)
///         return .none
///
///     // Single action response
///     case .fetchUser:
///         let user = try? await api.fetchUser()
///         return .single(._userLoaded(user))
///
///     // Multiple actions over time
///     case .downloadWithProgress:
///         return .stream { continuation in
///             downloader.onProgress { progress in
///                 continuation.yield(._progressUpdated(progress))
///             }
///             downloader.onComplete { result in
///                 continuation.yield(._downloadComplete(result))
///                 continuation.finish()
///             }
///         }
///     }
/// }
/// ```
public enum EffectOutput<Action>: Sendable where Action: Sendable {
    
    /// No action will be dispatched.
    ///
    /// Use this for fire-and-forget operations like logging or analytics.
    case none
    
    /// A single action will be dispatched.
    ///
    /// This is the most common case for effects like API calls.
    case single(Action)
    
    /// Multiple actions will be dispatched over time.
    ///
    /// Use this for streaming operations like WebSocket connections,
    /// file downloads with progress, or any long-running operation
    /// that produces multiple updates.
    case stream(AsyncStream<Action>)
}

// MARK: - Convenience Initializers

public extension EffectOutput {
    
    /// Creates a stream that emits multiple actions sequentially.
    ///
    /// - Parameter actions: The actions to emit.
    /// - Returns: An `EffectOutput` that will dispatch each action in order.
    ///
    /// ## Example
    /// ```swift
    /// return .actions(
    ///     ._setProgress(0.25),
    ///     ._setProgress(0.50),
    ///     ._setProgress(0.75),
    ///     ._setProgress(1.0),
    ///     ._loadingComplete
    /// )
    /// ```
    static func actions(_ actions: Action...) -> Self {
        .stream(AsyncStream { continuation in
            for action in actions {
                continuation.yield(action)
            }
            continuation.finish()
        })
    }
    
    /// Creates a stream from an array of actions.
    ///
    /// - Parameter actions: The actions to emit.
    /// - Returns: An `EffectOutput` that will dispatch each action in order.
    static func actions(_ actions: [Action]) -> Self {
        .stream(AsyncStream { continuation in
            for action in actions {
                continuation.yield(action)
            }
            continuation.finish()
        })
    }
    
    /// Creates a stream with a custom build closure.
    ///
    /// This provides full control over when and how actions are emitted.
    ///
    /// - Parameter build: A closure that receives an `AsyncStream.Continuation`
    ///   to yield actions and finish the stream.
    /// - Returns: An `EffectOutput` stream.
    ///
    /// ## Example
    /// ```swift
    /// return .stream { continuation in
    ///     webSocket.onMessage { message in
    ///         continuation.yield(._messageReceived(message))
    ///     }
    ///     webSocket.onDisconnect {
    ///         continuation.finish()
    ///     }
    /// }
    /// ```
    static func stream(
        _ build: @escaping @Sendable (AsyncStream<Action>.Continuation) -> Void
    ) -> Self {
        .stream(AsyncStream { continuation in
            build(continuation)
        })
    }
}

// MARK: - Map

public extension EffectOutput {
    
    /// Transforms the action type of this effect output.
    ///
    /// - Parameter transform: A closure that transforms each action.
    /// - Returns: A new `EffectOutput` with transformed actions.
    func map<NewAction: Sendable>(
        _ transform: @escaping @Sendable (Action) -> NewAction
    ) -> EffectOutput<NewAction> {
        switch self {
        case .none:
            return .none
            
        case .single(let action):
            return .single(transform(action))
            
        case .stream(let stream):
            return .stream(AsyncStream { continuation in
                Task {
                    for await action in stream {
                        continuation.yield(transform(action))
                    }
                    continuation.finish()
                }
            })
        }
    }
}
