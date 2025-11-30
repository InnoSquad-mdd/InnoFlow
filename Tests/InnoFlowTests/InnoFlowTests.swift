// MARK: - InnoFlowTests.swift
// InnoFlow - A Hybrid Architecture Framework for SwiftUI
// Copyright © 2025 InnoSquad. All rights reserved.

import Testing
import Foundation
@testable import InnoFlow
@testable import InnoFlowTesting

// MARK: - Test Feature (Counter)

struct CounterFeature: Reducer {
    
    struct State: Equatable, DefaultInitializable {
        var count = 0
        
        init() {}
        init(count: Int) { self.count = count }
    }
    
    enum Action: Equatable {
        case increment
        case decrement
        case reset
    }
    
    enum Mutation {
        case setCount(Int)
    }
    
    typealias Effect = Never
    
    func reduce(state: State, action: Action) -> Reduce<Mutation, Effect> {
        switch action {
        case .increment:
            return .mutation(.setCount(state.count + 1))
        case .decrement:
            return .mutation(.setCount(state.count - 1))
        case .reset:
            return .mutation(.setCount(0))
        }
    }
    
    func mutate(state: inout State, mutation: Mutation) {
        switch mutation {
        case .setCount(let value):
            state.count = value
        }
    }
    
    func handle(effect: Effect) async -> EffectOutput<Action> {
        // Never - unreachable
    }
}

// MARK: - Reduce Tests

@Suite("Reduce Tests")
struct ReduceTests {
    
    @Test("Reduce can be created with mutations only")
    func reduceMutationsOnly() {
        let reduce = Reduce<String, Int>.mutations(["a", "b"])
        
        #expect(reduce.mutations == ["a", "b"])
        #expect(reduce.effects.isEmpty)
    }
    
    @Test("Reduce can be created with effects only")
    func reduceEffectsOnly() {
        let reduce = Reduce<String, Int>.effects([1, 2, 3])
        
        #expect(reduce.mutations.isEmpty)
        #expect(reduce.effects == [1, 2, 3])
    }
    
    @Test("Reduce.none has no mutations or effects")
    func reduceNone() {
        let reduce = Reduce<String, Int>.none
        
        #expect(reduce.mutations.isEmpty)
        #expect(reduce.effects.isEmpty)
    }
    
    @Test("Reduce can be created with single mutation")
    func reduceSingleMutation() {
        let reduce = Reduce<String, Int>.mutation("single")
        
        #expect(reduce.mutations == ["single"])
        #expect(reduce.effects.isEmpty)
    }
    
    @Test("Reduce can be created with single effect")
    func reduceSingleEffect() {
        let reduce = Reduce<String, Int>.effect(42)
        
        #expect(reduce.mutations.isEmpty)
        #expect(reduce.effects == [42])
    }
}

// MARK: - EffectOutput Tests

@Suite("EffectOutput Tests")
struct EffectOutputTests {
    
    @Test("EffectOutput.none represents no action")
    func effectOutputNone() async {
        let output: EffectOutput<String> = .none
        
        if case .none = output {
            // Success
        } else {
            Issue.record("Expected .none")
        }
    }
    
    @Test("EffectOutput.single wraps a single action")
    func effectOutputSingle() async {
        let output: EffectOutput<String> = .single("action")
        
        if case .single(let action) = output {
            #expect(action == "action")
        } else {
            Issue.record("Expected .single")
        }
    }
    
    @Test("EffectOutput.actions creates a stream of actions")
    func effectOutputActions() async {
        let output: EffectOutput<Int> = .actions(1, 2, 3)
        
        if case .stream(let stream) = output {
            var collected: [Int] = []
            for await action in stream {
                collected.append(action)
            }
            #expect(collected == [1, 2, 3])
        } else {
            Issue.record("Expected .stream")
        }
    }
    
    @Test("EffectOutput.map transforms actions")
    func effectOutputMap() async {
        let output: EffectOutput<Int> = .single(5)
        let mapped = output.map { $0 * 2 }
        
        if case .single(let action) = mapped {
            #expect(action == 10)
        } else {
            Issue.record("Expected .single")
        }
    }
}

// MARK: - Store Tests

@Suite("Store Tests")
@MainActor
struct StoreTests {
    
    @Test("Store initializes with default state")
    func storeInitialization() {
        let store = Store(CounterFeature())
        
        #expect(store.state.count == 0)
        #expect(store.count == 0) // dynamicMemberLookup
    }
    
    @Test("Store initializes with custom initial state")
    func storeCustomInitialState() {
        let store = Store(CounterFeature(), initialState: .init(count: 10))
        
        #expect(store.count == 10)
    }
    
    @Test("Store processes increment action")
    func storeIncrement() {
        let store = Store(CounterFeature())
        
        store.send(.increment)
        #expect(store.count == 1)
        
        store.send(.increment)
        #expect(store.count == 2)
    }
    
    @Test("Store processes decrement action")
    func storeDecrement() {
        let store = Store(CounterFeature(), initialState: .init(count: 5))
        
        store.send(.decrement)
        #expect(store.count == 4)
    }
    
    @Test("Store processes reset action")
    func storeReset() {
        let store = Store(CounterFeature(), initialState: .init(count: 100))
        
        store.send(.reset)
        #expect(store.count == 0)
    }
    
    @Test("Dynamic member lookup provides state access")
    func dynamicMemberLookup() {
        let store = Store(CounterFeature(), initialState: .init(count: 42))
        
        // Both ways should work
        #expect(store.state.count == 42)
        #expect(store.count == 42) // dynamicMemberLookup
    }
}

// MARK: - Async Feature Tests

struct AsyncFeature: Reducer {
    
    struct State: Equatable, DefaultInitializable {
        var value: String = ""
        var isLoading = false
        
        init() {}
    }
    
    enum Action: Equatable, Sendable {
        case load
        case _loaded(String)
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setValue(String)
    }
    
    enum Effect: Sendable {
        case fetchValue
    }
    
    func reduce(state: State, action: Action) -> Reduce<Mutation, Effect> {
        switch action {
        case .load:
            return Reduce(
                mutations: [.setLoading(true)],
                effects: [.fetchValue]
            )
        case ._loaded(let value):
            return .mutations([.setValue(value), .setLoading(false)])
        }
    }
    
    func mutate(state: inout State, mutation: Mutation) {
        switch mutation {
        case .setLoading(let value): state.isLoading = value
        case .setValue(let value): state.value = value
        }
    }
    
    func handle(effect: Effect) async -> EffectOutput<Action> {
        switch effect {
        case .fetchValue:
            // Simulate async work
            try? await Task.sleep(for: .milliseconds(10))
            return .single(._loaded("Hello, InnoFlow!"))
        }
    }
}

@Suite("Async Feature Tests")
@MainActor
struct AsyncFeatureTests {
    
    @Test("Store handles async effects")
    func asyncEffect() async throws {
        let store = Store(AsyncFeature())
        
        store.send(.load)
        #expect(store.isLoading == true)
        
        // Wait for effect to complete
        try await Task.sleep(for: .milliseconds(100))
        
        #expect(store.value == "Hello, InnoFlow!")
        #expect(store.isLoading == false)
    }
}
