// MARK: - InnoFlowMacrosTests.swift
// InnoFlow - A Hybrid Architecture Framework for SwiftUI
// Copyright © 2025 InnoSquad. All rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

#if canImport(InnoFlowMacros)
import InnoFlowMacros

let testMacros: [String: Macro.Type] = [
    "Reducer": ReducerMacro.self,
]
#endif

@Suite("Macro Tests")
struct InnoFlowMacrosTests {
    
    @Test("Reducer macro adds conformance and Effect typealias")
    func reducerMacroAddsConformance() throws {
        #if canImport(InnoFlowMacros)
        assertMacroExpansion(
            """
            @Reducer
            struct CounterFeature {
                struct State: Equatable {
                    var count = 0
                }
                
                enum Action {
                    case increment
                }
                
                enum Mutation {
                    case setCount(Int)
                }
                
                func reduce(state: State, action: Action) -> Reduce<Mutation, Never> {
                    .none
                }
                
                func mutate(state: inout State, mutation: Mutation) {
                }
            }
            """,
            expandedSource: """
            struct CounterFeature {
                struct State: Equatable {
                    var count = 0
                }
                
                enum Action {
                    case increment
                }
                
                enum Mutation {
                    case setCount(Int)
                }
                
                func reduce(state: State, action: Action) -> Reduce<Mutation, Never> {
                    .none
                }
                
                func mutate(state: inout State, mutation: Mutation) {
                }

                typealias Effect = Never
            }
            extension CounterFeature: Reducer {
                func handle(effect: Effect) async -> EffectOutput<Action> {
                    // Never type - unreachable
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw Issue("Macros are only supported when running tests for the host platform")
        #endif
    }
    
    @Test("Reducer macro preserves existing Effect enum")
    func reducerMacroWithExistingEffect() throws {
        #if canImport(InnoFlowMacros)
        assertMacroExpansion(
            """
            @Reducer
            struct UserFeature {
                struct State: Equatable {
                    var user: String?
                }
                
                enum Action {
                    case load
                }
                
                enum Mutation {
                    case setUser(String?)
                }
                
                enum Effect {
                    case fetchUser
                }
                
                func reduce(state: State, action: Action) -> Reduce<Mutation, Effect> {
                    .none
                }
                
                func mutate(state: inout State, mutation: Mutation) {
                }
                
                func handle(effect: Effect) async -> EffectOutput<Action> {
                    .none
                }
            }
            """,
            expandedSource: """
            struct UserFeature {
                struct State: Equatable {
                    var user: String?
                }
                
                enum Action {
                    case load
                }
                
                enum Mutation {
                    case setUser(String?)
                }
                
                enum Effect {
                    case fetchUser
                }
                
                func reduce(state: State, action: Action) -> Reduce<Mutation, Effect> {
                    .none
                }
                
                func mutate(state: inout State, mutation: Mutation) {
                }
                
                func handle(effect: Effect) async -> EffectOutput<Action> {
                    .none
                }
            }

            extension UserFeature: Reducer {
            }
            """,
            macros: testMacros
        )
        #else
        throw Issue("Macros are only supported when running tests for the host platform")
        #endif
    }
}
