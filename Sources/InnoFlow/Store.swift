// MARK: - Store.swift
// InnoFlow - A Hybrid Architecture Framework for SwiftUI
// Copyright © 2025 InnoSquad. All rights reserved.

import Foundation
import Observation
import SwiftUI
import Synchronization

// MARK: - Effect Tasks Storage (Thread-Safe with Mutex)

/// A thread-safe container for storing effect tasks.
/// Uses Swift's native Mutex for synchronization.
final class EffectTasksStorage: Sendable {
    private let storage = Mutex<[UUID: Task<Void, Never>]>([:])
    
    func set(_ task: Task<Void, Never>, forKey key: UUID) {
        storage.withLock { $0[key] = task }
    }
    
    func removeValue(forKey key: UUID) {
        storage.withLock { _ = $0.removeValue(forKey: key) }
    }
    
    func cancelAll() {
        storage.withLock { tasks in
            for task in tasks.values {
                task.cancel()
            }
            tasks.removeAll()
        }
    }
}

/// A store that manages state and processes actions for a feature.
///
/// `Store` is the runtime that connects your `Reducer` to SwiftUI.
/// It observes state changes and re-renders views automatically.
///
/// ## Features
/// - Built on Swift's `@Observable` for seamless SwiftUI integration
/// - `@dynamicMemberLookup` for convenient state access (`store.count` instead of `store.state.count`)
/// - Thread-safe with `@MainActor`
/// - Automatic effect handling and action dispatching
///
/// ## Example
/// ```swift
/// struct CounterView: View {
///     @State private var store = Store(CounterFeature())
///
///     var body: some View {
///         VStack {
///             Text("Count: \(store.count)")  // Direct access via dynamicMemberLookup
///             Button("Increment") {
///                 store.send(.increment)
///             }
///         }
///     }
/// }
/// ```
@Observable
@MainActor
@dynamicMemberLookup
public final class Store<R: Reducer> {
    
    // MARK: - Properties
    
    /// The current state of the store.
    ///
    /// This is observable and will trigger view updates when changed.
    public private(set) var state: R.State
    
    /// The reducer that processes actions.
    private let reducer: R
    
    /// Active effect tasks for cancellation support.
    /// Stored in a thread-safe container to allow safe access from deinit.
    private let effectTasks = EffectTasksStorage()
    
    // MARK: - Initialization
    
    /// Creates a new store with the given reducer.
    ///
    /// - Parameters:
    ///   - reducer: The reducer that defines the feature's logic.
    ///   - initialState: Optional initial state. If not provided, uses the reducer's default.
    public init(_ reducer: R, initialState: R.State? = nil) where R.State: DefaultInitializable {
        self.reducer = reducer
        self.state = initialState ?? R.State()
    }
    
    /// Creates a new store with the given reducer and initial state.
    ///
    /// - Parameters:
    ///   - reducer: The reducer that defines the feature's logic.
    ///   - initialState: The initial state for the store.
    public init(_ reducer: R, initialState: R.State) {
        self.reducer = reducer
        self.state = initialState
    }
    
    // MARK: - Dynamic Member Lookup
    
    /// Provides direct access to state properties.
    ///
    /// Instead of `store.state.count`, you can write `store.count`.
    /// For `BindableProperty` values, automatically unwraps to the underlying value.
    public subscript<Value>(dynamicMember keyPath: KeyPath<R.State, Value>) -> Value {
        state[keyPath: keyPath]
    }
    
    /// Provides direct access to `BindableProperty` values, unwrapping them automatically.
    ///
    /// This allows `store.step` to work even when `step` is a `BindableProperty<Int>`.
    public subscript<Value>(dynamicMember keyPath: KeyPath<R.State, BindableProperty<Value>>) -> Value where Value: Equatable & Sendable {
        state[keyPath: keyPath].value
    }
    
    // MARK: - Action Dispatch
    
    /// Sends an action to the store for processing.
    ///
    /// This is the primary way to interact with the store.
    /// Actions are processed synchronously, but effects run asynchronously.
    ///
    /// - Parameter action: The action to process.
    ///
    /// ## Example
    /// ```swift
    /// store.send(.load)
    /// store.send(.buttonTapped)
    /// store.send(.textChanged("Hello"))
    /// ```
    public func send(_ action: R.Action) {
        // 1. Reduce: Action → Mutations + Effects
        let result = reducer.reduce(state: state, action: action)
        
        // 2. Apply mutations to state
        for mutation in result.mutations {
            reducer.mutate(state: &state, mutation: mutation)
        }
        
        // 3. Execute effects
        for effect in result.effects {
            executeEffect(effect)
        }
    }
    
    // MARK: - Effect Execution
    
    /// Executes a single effect and dispatches resulting actions.
    private func executeEffect(_ effect: R.Effect) {
        let taskID = UUID()
        
        let task = Task { @MainActor [weak self, reducer] in
            guard let self else { return }
            
            let output = await reducer.handle(effect: effect)
            
            self.processEffectOutput(output)
            self.effectTasks.removeValue(forKey: taskID)
        }
        
        effectTasks.set(task, forKey: taskID)
    }
    
    /// Processes the output of an effect.
    private func processEffectOutput(_ output: EffectOutput<R.Action>) {
        switch output {
        case .none:
            break
            
        case .single(let action):
            send(action)
            
        case .stream(let stream):
            Task { @MainActor [weak self] in
                guard let self else { return }
                for await action in stream {
                    self.send(action)
                }
            }
        }
    }
    
    // MARK: - Lifecycle
    
    /// Cancels all running effects.
    ///
    /// Call this when the view disappears or the store is no longer needed.
    public func cancelAllEffects() {
        effectTasks.cancelAll()
    }
    
    deinit {
        effectTasks.cancelAll()
    }
}

// MARK: - Bindable Property

/// A wrapper type for state properties that can be used with `store.binding(_:send:)`.
///
/// Properties marked with `@BindableField` are automatically wrapped in this type.
/// This ensures type safety by only allowing binding to explicitly marked fields.
///
/// ## Example
/// ```swift
/// struct State: Equatable {
///     @BindableField var name = ""      // Wrapped as BindableProperty<String>
///     var isLoading = false             // Not bindable
/// }
/// ```
@dynamicMemberLookup
public struct BindableProperty<Value>: Equatable, Sendable where Value: Equatable & Sendable {
    public var value: Value
    
    public init(_ value: Value) {
        self.value = value
    }
    
    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
        value[keyPath: keyPath]
    }
}

// MARK: - Default Initializable Protocol

/// A protocol for types that can be initialized with no arguments.
///
/// Conform your `State` to this protocol to enable
/// `Store(MyFeature())` without specifying initial state.
public protocol DefaultInitializable {
    init()
}

// MARK: - Binding Support

public extension Store {
    
    /// Creates a binding to a bindable state property.
    ///
    /// Only properties marked with `@BindableField` can be used with this method.
    /// The setter dispatches an action to update the state.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the bindable property value.
    ///   - action: A closure that creates an action from the new value.
    /// - Returns: A `Binding` that reads from state and writes via actions.
    ///
    /// ## Example
    /// ```swift
    /// struct State: Equatable {
    ///     @BindableField var step = 1
    /// }
    ///
    /// Stepper("Step", value: store.binding(
    ///     \.step,
    ///     send: { .setStep($0) }
    /// ))
    /// ```
    func binding<Value>(
        _ keyPath: KeyPath<R.State, Value>,
        send action: @escaping (Value) -> R.Action
    ) -> Binding<Value> where Value: Equatable & Sendable {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.send(action($0)) }
        )
    }
    
    /// Creates a binding to a bindable state property (explicit BindableProperty type).
    ///
    /// This overload is for cases where the property is explicitly typed as `BindableProperty<Value>`.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the `BindableProperty` value.
    ///   - action: A closure that creates an action from the new value.
    /// - Returns: A `Binding` that reads from state and writes via actions.
    func binding<Value>(
        _ keyPath: KeyPath<R.State, BindableProperty<Value>>,
        send action: @escaping (Value) -> R.Action
    ) -> Binding<Value> where Value: Equatable & Sendable {
        Binding(
            get: { self.state[keyPath: keyPath].value },
            set: { self.send(action($0)) }
        )
    }
    
    /// Creates a binding to an optional bindable state property with a default.
    ///
    /// Only properties wrapped in `BindableProperty` (marked with `@BindableField`) can be used with this method.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the optional `BindableProperty` value.
    ///   - default: The default value when state is nil.
    ///   - action: A closure that creates an action from the new value.
    /// - Returns: A `Binding` with the specified default value.
    func binding<Value>(
        _ keyPath: KeyPath<R.State, BindableProperty<Value>?>,
        default defaultValue: Value,
        send action: @escaping (Value?) -> R.Action
    ) -> Binding<Value> where Value: Equatable & Sendable {
        Binding(
            get: { self.state[keyPath: keyPath]?.value ?? defaultValue },
            set: { self.send(action($0)) }
        )
    }
}

// MARK: - Scoping (Child Stores)

public extension Store {
    
    /// Creates a derived store focused on a subset of state.
    ///
    /// Use this to pass a portion of your state to a child view
    /// without exposing the entire store.
    ///
    /// - Parameters:
    ///   - state: A key path to the child state.
    ///   - action: A closure that wraps child actions into parent actions.
    /// - Returns: A `ScopedStore` that views a subset of the parent state.
    func scope<ChildState, ChildAction>(
        state: KeyPath<R.State, ChildState>,
        action: @escaping (ChildAction) -> R.Action
    ) -> ScopedStore<R, ChildState, ChildAction> {
        ScopedStore(parent: self, stateKeyPath: state, actionTransform: action)
    }
}

// MARK: - Scoped Store

/// A read-only view into a parent store's state subset.
///
/// `ScopedStore` allows child views to access only the state they need
/// while still dispatching actions through the parent store.
@Observable
@MainActor
@dynamicMemberLookup
public final class ScopedStore<ParentReducer: Reducer, ChildState, ChildAction> {
    
    private let parent: Store<ParentReducer>
    private let stateKeyPath: KeyPath<ParentReducer.State, ChildState>
    private let actionTransform: (ChildAction) -> ParentReducer.Action
    
    /// The current child state.
    public var state: ChildState {
        parent.state[keyPath: stateKeyPath]
    }
    
    init(
        parent: Store<ParentReducer>,
        stateKeyPath: KeyPath<ParentReducer.State, ChildState>,
        actionTransform: @escaping (ChildAction) -> ParentReducer.Action
    ) {
        self.parent = parent
        self.stateKeyPath = stateKeyPath
        self.actionTransform = actionTransform
    }
    
    public subscript<Value>(dynamicMember keyPath: KeyPath<ChildState, Value>) -> Value {
        state[keyPath: keyPath]
    }
    
    public func send(_ action: ChildAction) {
        parent.send(actionTransform(action))
    }
}
