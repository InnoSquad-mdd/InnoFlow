// MARK: - TestStore.swift
// InnoFlow - A Hybrid Architecture Framework for SwiftUI
// Copyright © 2025 InnoSquad. All rights reserved.

import Foundation
import InnoFlow

/// A store designed for testing InnoFlow features.
///
/// `TestStore` provides a structured way to test your reducers by:
/// - Verifying state changes after sending actions
/// - Asserting that expected effects are triggered
/// - Receiving and verifying effect-generated actions
/// - Supporting exhaustive testing of action/mutation flows
///
/// ## Basic Example
/// ```swift
/// @Test
/// func testIncrement() async {
///     let store = TestStore(CounterFeature())
///
///     await store.send(.increment) {
///         $0.count = 1
///     }
///
///     await store.send(.increment) {
///         $0.count = 2
///     }
/// }
/// ```
///
/// ## Testing Effects
/// ```swift
/// @Test
/// func testLoadUser() async {
///     let store = TestStore(
///         UserFeature(api: MockAPI(user: User(name: "Test")))
///     )
///
///     await store.send(.load) {
///         $0.isLoading = true
///     }
///
///     await store.receive(._loaded(User(name: "Test"))) {
///         $0.user = User(name: "Test")
///         $0.isLoading = false
///     }
/// }
/// ```
@MainActor
public final class TestStore<R: Reducer> where R.State: Equatable {
    
    // MARK: - Properties
    
    /// The current state of the store.
    public private(set) var state: R.State
    
    /// The reducer being tested.
    private let reducer: R
    
    /// Received actions from effects (FIFO queue).
    private var receivedActions: [R.Action] = []
    
    /// Pending effects that haven't completed.
    private var pendingEffects: [Task<Void, Never>] = []
    
    /// Timeout for waiting on effects.
    private let effectTimeout: Duration
    
    // MARK: - Initialization
    
    /// Creates a test store with the given reducer.
    ///
    /// - Parameters:
    ///   - reducer: The reducer to test.
    ///   - initialState: Optional initial state override.
    ///   - effectTimeout: Maximum time to wait for effects. Defaults to 1 second.
    public init(
        _ reducer: R,
        initialState: R.State? = nil,
        effectTimeout: Duration = .seconds(1)
    ) where R.State: DefaultInitializable {
        self.reducer = reducer
        self.state = initialState ?? R.State()
        self.effectTimeout = effectTimeout
    }
    
    /// Creates a test store with explicit initial state.
    ///
    /// - Parameters:
    ///   - reducer: The reducer to test.
    ///   - initialState: The initial state.
    ///   - effectTimeout: Maximum time to wait for effects. Defaults to 1 second.
    public init(
        _ reducer: R,
        initialState: R.State,
        effectTimeout: Duration = .seconds(1)
    ) {
        self.reducer = reducer
        self.state = initialState
        self.effectTimeout = effectTimeout
    }
    
    // MARK: - Send Action
    
    /// Sends an action to the store and asserts the resulting state changes.
    ///
    /// - Parameters:
    ///   - action: The action to send.
    ///   - updateExpectedState: A closure that modifies the expected state.
    ///     The closure receives the current state, and you should mutate it
    ///     to reflect the expected changes.
    ///   - file: The file where the assertion is called.
    ///   - line: The line where the assertion is called.
    ///
    /// ## Example
    /// ```swift
    /// await store.send(.increment) {
    ///     $0.count = 1  // Assert count becomes 1
    /// }
    /// ```
    public func send(
        _ action: R.Action,
        assert updateExpectedState: ((inout R.State) -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        // Get mutations and effects
        let result = reducer.reduce(state: state, action: action)
        
        // Apply mutations
        var newState = state
        for mutation in result.mutations {
            reducer.mutate(state: &newState, mutation: mutation)
        }
        
        // If assertion provided, verify state matches
        if let updateExpectedState {
            var expectedState = state
            updateExpectedState(&expectedState)
            
            if newState != expectedState {
                testStoreAssertionFailure(
                    """
                    State mismatch after action.
                    
                    Expected:
                    \(expectedState)
                    
                    Actual:
                    \(newState)
                    """,
                    file: file,
                    line: line
                )
            }
        }
        
        // Update state
        state = newState
        
        // Execute effects and collect resulting actions
        for effect in result.effects {
            let task = Task { @MainActor [reducer] in
                let output = await reducer.handle(effect: effect)
                self.processEffectOutput(output)
            }
            pendingEffects.append(task)
        }
        
        // Wait briefly for immediate effects
        if !result.effects.isEmpty {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
    
    // MARK: - Receive Action
    
    /// Waits for and asserts an action received from an effect.
    ///
    /// Use this to verify that effects dispatch the expected actions.
    ///
    /// - Parameters:
    ///   - expectedAction: The action you expect to receive.
    ///   - updateExpectedState: A closure that modifies the expected state.
    ///   - file: The file where the assertion is called.
    ///   - line: The line where the assertion is called.
    ///
    /// ## Example
    /// ```swift
    /// await store.receive(._loaded(.success(users))) {
    ///     $0.users = users
    ///     $0.isLoading = false
    /// }
    /// ```
    public func receive(
        _ expectedAction: R.Action,
        assert updateExpectedState: ((inout R.State) -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async where R.Action: Equatable {
        // Wait for effects to complete
        await waitForEffects()
        
        // Check if we received the expected action
        guard !receivedActions.isEmpty else {
            testStoreAssertionFailure(
                """
                Expected to receive action:
                \(expectedAction)
                
                But no actions were received.
                """,
                file: file,
                line: line
            )
            return
        }
        
        let receivedAction = receivedActions.removeFirst()
        
        if receivedAction != expectedAction {
            testStoreAssertionFailure(
                """
                Received unexpected action.
                
                Expected:
                \(expectedAction)
                
                Received:
                \(receivedAction)
                """,
                file: file,
                line: line
            )
        }
        
        // Process the received action
        let result = reducer.reduce(state: state, action: receivedAction)
        
        var newState = state
        for mutation in result.mutations {
            reducer.mutate(state: &newState, mutation: mutation)
        }
        
        // Verify state if assertion provided
        if let updateExpectedState {
            var expectedState = state
            updateExpectedState(&expectedState)
            
            if newState != expectedState {
                testStoreAssertionFailure(
                    """
                    State mismatch after receiving action.
                    
                    Expected:
                    \(expectedState)
                    
                    Actual:
                    \(newState)
                    """,
                    file: file,
                    line: line
                )
            }
        }
        
        state = newState
        
        // Handle any effects from this action
        for effect in result.effects {
            let task = Task { @MainActor [reducer] in
                let output = await reducer.handle(effect: effect)
                self.processEffectOutput(output)
            }
            pendingEffects.append(task)
        }
    }
    
    // MARK: - Helpers
    
    /// Processes effect output and queues resulting actions.
    private func processEffectOutput(_ output: EffectOutput<R.Action>) {
        switch output {
        case .none:
            break
            
        case .single(let action):
            receivedActions.append(action)
            
        case .stream(let stream):
            Task { @MainActor in
                for await action in stream {
                    self.receivedActions.append(action)
                }
            }
        }
    }
    
    /// Waits for all pending effects to complete.
    private func waitForEffects() async {
        // Wait for pending tasks
        for task in pendingEffects {
            await task.value
        }
        pendingEffects.removeAll()
        
        // Small delay to allow actions to be queued
        try? await Task.sleep(for: .milliseconds(50))
    }
    
    /// Asserts that there are no unhandled received actions.
    ///
    /// Call this at the end of your test to ensure all effect actions
    /// were properly received and verified.
    public func assertNoMoreActions(
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await waitForEffects()
        
        if !receivedActions.isEmpty {
            testStoreAssertionFailure(
                """
                Unhandled received actions:
                \(receivedActions)
                
                All effect actions should be verified with `receive(_:assert:)`.
                """,
                file: file,
                line: line
            )
        }
    }
}

// MARK: - Assertion Helper (for XCTest compatibility)

private func testStoreAssertionFailure(
    _ message: String,
    file: StaticString,
    line: UInt
) {
    #if DEBUG
    print("❌ TestStore Assertion Failed:")
    print(message)
    print("File: \(file), Line: \(line)")
    #endif
    
    // In real XCTest, this would be XCTFail
    // For now, we'll use Swift's assertionFailure in debug
    Swift.assertionFailure(message, file: file, line: line)
}
