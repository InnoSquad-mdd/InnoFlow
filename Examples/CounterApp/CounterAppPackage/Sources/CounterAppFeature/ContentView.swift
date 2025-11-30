import SwiftUI
import InnoFlow

// MARK: - CounterFeature

@InnoFlow
struct CounterFeature {
    
    struct State: Equatable, DefaultInitializable {
        var count = 0
        @BindableField var step = 1
    }
    
    enum Action: Sendable {
        case increment
        case decrement
        case reset
        case setStep(Int)
    }
    
    enum Mutation {
        case setCount(Int)
        case setStep(Int)
    }
    
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
    
    func mutate(state: inout State, mutation: Mutation) {
        switch mutation {
        case .setCount(let count):
            state.count = count
            
        case .setStep(let step):
            state.step = max(1, step)
        }
    }
}

// MARK: - CounterView

public struct ContentView: View {
    @State private var store = Store(CounterFeature())
    
    public var body: some View {
        VStack(spacing: 30) {
            Text("\(store.count)")
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(store.count == 0 ? .secondary : .primary)
            
            HStack(spacing: 20) {
                Button(action: { store.send(.decrement) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                }
                .buttonStyle(.bordered)
                
                Button(action: { store.send(.reset) }) {
                    Text("리셋")
                        .font(.headline)
                        .frame(width: 80)
                }
                .buttonStyle(.bordered)
                .disabled(store.count == 0)
                
                Button(action: { store.send(.increment) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
                .padding(.vertical)
            
            VStack(spacing: 12) {
                Text("증감 단위: \(store.step)")
                    .font(.headline)
                
                Stepper(
                    "스텝",
                    value: store.binding(\.step, send: { .setStep($0) }),
                    in: 1...10
                )
                .labelsHidden()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .navigationTitle("카운터")
        .navigationBarTitleDisplayMode(.large)
    }
    
    public init() {}
}
