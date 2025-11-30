# InnoFlow

A lightweight, hybrid architecture framework for SwiftUI that combines the best of Elm Architecture with SwiftUI's native `@Observable` pattern.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2018.0%2B%20%7C%20macOS%2015.0%2B%20%7C%20tvOS%2018.0%2B%20%7C%20watchOS%2011.0%2B-lightgrey.svg)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Xcode](https://img.shields.io/badge/Xcode-16.0%2B-blue.svg)](https://developer.apple.com/xcode/)
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue.svg)](https://innosquad-mdd.github.io/InnoFlow/documentation/innoflow/)

**By [Inno Squad](https://github.com/innosquad-mdd)**

---

## 🎯 Philosophy

InnoFlow bridges the gap between SwiftUI's declarative simplicity and robust state management:

- **SwiftUI-Native**: Built on `@Observable` for seamless integration
- **Unidirectional Data Flow**: `Action → Reduce → Mutation → State → View`
- **Testable**: First-class testing support with `TestStore`
- **Lightweight**: Minimal boilerplate compared to other architectures
- **Flexible DI**: Bring your own dependency injection strategy

## 📦 Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/innosquad-mdd/InnoFlow.git", from: "1.0.0")
]
```

```swift
// In your target
.target(
    name: "YourApp",
    dependencies: ["InnoFlow"]
)

// For tests
.testTarget(
    name: "YourAppTests",
    dependencies: ["InnoFlow", "InnoFlowTesting"]
)
```

## 🚀 Quick Start

### 1. Define Your Feature

```swift
import InnoFlow

@InnoFlow
struct CounterFeature {
    // State: What data does this feature manage?
    struct State: Equatable {
        var count = 0
        @BindableField var step = 1  // Bindable property for two-way binding
    }
    
    // Action: What can happen?
    enum Action {
        case increment
        case decrement
        case setStep(Int)
    }
    
    // Mutation: How does state change?
    enum Mutation {
        case setCount(Int)
        case setStep(Int)
    }
    
    // Reduce: Action → Mutations + Effects
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
    
    // Mutate: Apply mutation to state
    func mutate(state: inout State, mutation: Mutation) {
        switch mutation {
        case .setCount(let value):
            state.count = value
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
            Text("Count: \(store.count)")  // Direct access via @dynamicMemberLookup
                .font(.largeTitle)
            
            HStack(spacing: 40) {
                Button("−") { store.send(.decrement) }
                Button("+") { store.send(.increment) }
            }
            .font(.title)
            
            Stepper("Step: \(store.step)", value: store.binding(
                \.step,
                send: { .setStep($0) }
            ))
        }
    }
}
```

## 🔄 Handling Side Effects

For async operations like API calls:

```swift
@InnoFlow
struct UserFeature {
    struct State: Equatable {
        var user: User?
        var isLoading = false
        var error: String?
    }
    
    enum Action: Sendable {
        case load
        case refresh
        case _loaded(Result<User, Error>)  // Internal action (prefix with _)
    }
    
    enum Mutation {
        case setLoading(Bool)
        case setUser(User?)
        case setError(String?)
    }
    
    enum Effect: Sendable {
        case fetchUser
    }
    
    // Dependency injection via init
    let userService: UserServiceProtocol
    
    init(userService: UserServiceProtocol = UserService.shared) {
        self.userService = userService
    }
    
    func reduce(state: State, action: Action) -> Reduce<Mutation, Effect> {
        switch action {
        case .load, .refresh:
            return Reduce(
                mutations: [.setLoading(true), .setError(nil)],
                effects: [.fetchUser]
            )
            
        case ._loaded(.success(let user)):
            return .mutations([.setUser(user), .setLoading(false)])
            
        case ._loaded(.failure(let error)):
            return .mutations([
                .setError(error.localizedDescription),
                .setLoading(false)
            ])
        }
    }
    
    func mutate(state: inout State, mutation: Mutation) {
        switch mutation {
        case .setLoading(let value): state.isLoading = value
        case .setUser(let user): state.user = user
        case .setError(let error): state.error = error
        }
    }
    
    func handle(effect: Effect) async -> EffectOutput<Action> {
        switch effect {
        case .fetchUser:
            do {
                let user = try await userService.fetchUser()
                return .single(._loaded(.success(user)))
            } catch {
                return .single(._loaded(.failure(error)))
            }
        }
    }
}
```

## 📊 Effect Output Types

InnoFlow supports multiple effect output types:

```swift
func handle(effect: Effect) async -> EffectOutput<Action> {
    switch effect {
    
    // No action (fire-and-forget)
    case .logAnalytics:
        analytics.log("event")
        return .none
    
    // Single action
    case .fetchData:
        let data = try? await api.fetch()
        return .single(._dataLoaded(data))
    
    // Multiple actions
    case .multiStep:
        return .actions(
            ._step1Complete,
            ._step2Complete,
            ._allComplete
        )
    
    // Streaming (WebSocket, progress, etc.)
    case .subscribe:
        return .stream { continuation in
            webSocket.onMessage { msg in
                continuation.yield(._messageReceived(msg))
            }
            webSocket.onClose {
                continuation.finish()
            }
        }
    }
}
```

## 🧪 Testing

InnoFlow provides `TestStore` for comprehensive testing:

```swift
import Testing
import InnoFlow
import InnoFlowTesting

@Test
func testIncrement() async {
    let store = TestStore(CounterFeature())
    
    await store.send(.increment) {
        $0.count = 1
    }
    
    await store.send(.increment) {
        $0.count = 2
    }
}

@Test
func testAsyncLoad() async {
    let mockService = MockUserService(user: User(name: "Test"))
    let store = TestStore(UserFeature(userService: mockService))
    
    await store.send(.load) {
        $0.isLoading = true
    }
    
    await store.receive(._loaded(.success(User(name: "Test")))) {
        $0.user = User(name: "Test")
        $0.isLoading = false
    }
    
    await store.assertNoMoreActions()
}
```

## 🔗 Bindings

Create bindings for two-way data flow using `@BindableField`:

### Using @BindableField

Mark state properties with `@BindableField` to enable type-safe bindings:

```swift
@InnoFlow
struct FormFeature {
    struct State: Equatable {
        @BindableField var name = ""      // Automatically wrapped in BindableProperty
        @BindableField var step = 1       // Automatically wrapped in BindableProperty
        var isLoading = false             // Not bindable
    }
    
    enum Action {
        case nameChanged(String)
        case setStep(Int)
    }
    
    // ... reduce, mutate implementations ...
}

struct FormView: View {
    @State private var store = Store(FormFeature())
    
    var body: some View {
        Form {
            TextField("Name", text: store.binding(
                \.name,
                send: { .nameChanged($0) }
            ))
            
            Stepper("Step", value: store.binding(
                \.step,
                send: { .setStep($0) }
            ))
        }
    }
}
```

**Note:** Only properties marked with `@BindableField` can be used with `store.binding(_:send:)`. This ensures type safety and makes it explicit which fields support two-way binding.

## 🏗 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                        View                             │
│                    (SwiftUI)                            │
└─────────────────────┬───────────────────────────────────┘
                      │ send(Action)
                      ▼
┌─────────────────────────────────────────────────────────┐
│                       Store                             │
│            (@Observable, @MainActor)                    │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                      Reducer                            │
│         reduce(state:action:) → Reduce                  │
└─────────────────────┬───────────────────────────────────┘
                      │
          ┌───────────┴───────────┐
          ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│   [Mutation]    │     │    [Effect]     │
└────────┬────────┘     └────────┬────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│     mutate()    │     │    handle()     │
│  State update   │     │  Async work     │
└────────┬────────┘     └────────┬────────┘
         │                       │
         ▼                       │
┌─────────────────┐              │
│      State      │◄─────────────┘
│    (updated)    │      Action (from effect)
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│                     View Update                         │
│              (Automatic via @Observable)                │
└─────────────────────────────────────────────────────────┘
```

## 📋 Requirements

- iOS 18.0+ / macOS 15.0+ / tvOS 18.0+ / watchOS 11.0+
- Swift 6.0+
- Xcode 16.0+

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

## 📚 Additional Resources

- [📖 API Documentation](https://innosquad-mdd.github.io/InnoFlow/documentation/innoflow/) - Full API reference (DocC)
- [Examples](Examples/) - Sample apps demonstrating InnoFlow usage
- [Changelog](CHANGELOG.md) - Version history and changes

---

**Made with ❤️ by InnoSquad**
