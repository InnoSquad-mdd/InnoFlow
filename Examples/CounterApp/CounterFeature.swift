// MARK: - CounterFeature.swift
// 간단한 카운터 기능을 위한 Reducer

import Foundation
import InnoFlow

/// 카운터 기능을 관리하는 Feature
/// Effect가 없는 간단한 예제
@Reducer
struct CounterFeature {
    
    // MARK: - State
    
    struct State: Equatable, DefaultInitializable {
        var count = 0
        var step = 1
    }
    
    // MARK: - Action
    
    enum Action: Sendable {
        case increment
        case decrement
        case reset
        case setStep(Int)
    }
    
    // MARK: - Mutation
    
    enum Mutation {
        case setCount(Int)
        case setStep(Int)
    }
    
    // Effect는 없음 (Never 타입으로 자동 생성됨)
    
    // MARK: - Reduce
    
    func reduce(state: State, action: Action) -> Reduce<Mutation, Never> {
        switch action {
        case .increment:
            return .mutation(.setCount(state.count + state.step))
            
        case .decrement:
            return .mutation(.setCount(state.count - state.step))
            
        case .reset:
            return .mutation(.setCount(0))
            
        case .setStep(let step):
            return .mutation(.setStep(step))
        }
    }
    
    // MARK: - Mutate
    
    func mutate(state: inout State, mutation: Mutation) {
        switch mutation {
        case .setCount(let count):
            state.count = count
            
        case .setStep(let step):
            state.step = max(1, step) // 최소값 1
        }
    }
    
    // handle(effect:)는 Effect가 Never이므로 자동으로 기본 구현 제공됨
}



