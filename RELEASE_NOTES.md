# InnoFlow 1.0.0 Release Notes

We're excited to announce the initial release of **InnoFlow** - a lightweight, hybrid architecture framework for SwiftUI that combines the best of Elm Architecture with SwiftUI's native `@Observable` pattern.

## 🎉 What is InnoFlow?

InnoFlow provides a clean, testable architecture for SwiftUI apps with:
- **Unidirectional Data Flow**: `Action → Reduce → Mutation → State → View`
- **SwiftUI-Native**: Built on `@Observable` for seamless integration
- **Type-Safe**: Leverages Swift's type system for compile-time safety
- **Testable**: First-class testing support with `TestStore`
- **Lightweight**: Minimal boilerplate compared to other architectures

## ✨ Key Features

### Core Architecture
- **Store**: Observable state container that automatically updates SwiftUI views
- **Reducer**: Protocol-based feature definition with clear separation of concerns
- **Action/Mutation/Effect**: Clean separation between user actions, state changes, and side effects

### Swift Macros
- **@InnoFlow**: Automatically generates boilerplate code and protocol conformance
- **@BindableField**: Type-safe two-way bindings for SwiftUI controls

### Effect System
- Support for async operations (API calls, database access, etc.)
- Multiple effect output types: `.none`, `.single`, `.stream`
- Automatic effect cancellation

### Testing
- **TestStore**: Comprehensive testing utilities
- Action and state assertion support
- Effect testing with action verification

## 📦 Installation

### Swift Package Manager

Add InnoFlow to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/innosquad-mdd/InnoFlow.git", from: "1.0.0")
]
```

Or add it in Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/innosquad-mdd/InnoFlow.git`
3. Select version: `1.0.0`

## 🚀 Quick Start

### 1. Define Your Feature

```swift
import InnoFlow

@InnoFlow
struct CounterFeature {
    struct State: Equatable {
        var count = 0
        @BindableField var step = 1
    }
    
    enum Action {
        case increment
        case decrement
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
```

### 2. Use in SwiftUI

```swift
struct CounterView: View {
    @State private var store = Store(CounterFeature())
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(store.count)")
                .font(.largeTitle)
            
            HStack(spacing: 40) {
                Button("−") { store.send(.decrement) }
                Button("+") { store.send(.increment) }
            }
            
            Stepper("Step: \(store.step)", value: store.binding(
                \.step,
                send: { .setStep($0) }
            ))
        }
    }
}
```

## 📚 Documentation

- [README](README.md) - Complete guide and API reference
- [Examples](Examples/) - Sample apps demonstrating InnoFlow usage
- [Changelog](CHANGELOG.md) - Version history

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

InnoFlow is inspired by:
- The Elm Architecture
- TCA (The Composable Architecture)
- SwiftUI's `@Observable` pattern

---

**Made with ❤️ by InnoSquad**

For questions, issues, or feature requests, please open an issue on GitHub.

