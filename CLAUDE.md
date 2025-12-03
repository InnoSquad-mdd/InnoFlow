# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Developer Guidelines

### Language Policy
- I am Korean.
- Even if I ask questions in English, please respond in Korean unless I am explicitly requesting or handling a system prompt.
- PR description always in Korean.

### Root Cause First Approach
- I am an iOS Engineer.
- I value fundamental problem solving.
- When addressing an issue, do not suggest code modifications first.
  Instead:
  - Carefully review whether the provided context is sufficient.
  - For iOS issues, always consider:
    - Reproducibility (device vs simulator, iOS version, build configuration).
    - Logs and crash reports (Xcode console, OSLog, crash logs, Instruments).
    - App lifecycle and state (foreground/background, navigation stack, async tasks).
  - Identify the root cause before proposing any code changes.

### Avoid Focusing on Passing Tests and Hard-coding
- Please write a high quality, general purpose solution. Implement a solution that works correctly for all valid inputs, not just the test cases.
  Do not hard-code values or create solutions that only work for specific test inputs.
  Instead, implement the actual logic that solves the problem generally.
- Focus on understanding the problem requirements and implementing the correct algorithm or architecture.
  For iOS:
  - Respect the chosen architecture (e.g. MVVM, unidirectional data flow, InnoFlow/TCA-style patterns).
  - Keep side effects isolated and testable (networking, persistence, analytics, etc.).
- Tests are there to verify correctness, not to define the solution.
  Provide a principled implementation that follows best practices and software design principles:
  - Prefer pure functions and small, composable types where possible.
  - Keep UIKit/SwiftUI views thin and move business logic out of the view layer.
  - Avoid leaking implementation details into public APIs.
- If the task is unreasonable or infeasible, or if any of the tests are incorrect, please tell me.
  The solution should be robust, maintainable, and extendable:
  - Consider performance (main thread usage, layout cost, unnecessary re-renders).
  - Consider memory (retain cycles, long-living closures, async tasks).

### iOS-specific Guidelines
- UI updates must occur on the main thread. Do not perform heavy work on the main actor unless strictly necessary.
- Handle lifecycle correctly:
  - Understand the difference between app launch, scene activation, view appearance, and background transitions.
  - Avoid relying on undefined timing (e.g. assuming viewDidLoad/viewDidAppear order for logic that should live in the model/store).
- For async work (networking, database, etc.):
  - Use structured concurrency (`async/await`, `Task` boundaries) and avoid unstructured "fire-and-forget" unless intentional.
  - Make types `Sendable` where appropriate and be explicit about actor isolation.
- Prefer dependency injection over singletons for testability and flexibility (e.g. API clients, storage, feature flags).

### Git and Version Control
- Branch name always in English.
- Commit message is always in English.
- DO NOT git add unstaged changes unless specified.
- Do not commit generated or local-only files (DerivedData, .xcuserdata, etc.).
- Keep commits focused and logically grouped (feature, fix, refactor, chore, etc.).

## Project Overview

InnoFlow is a lightweight, hybrid architecture framework for SwiftUI that combines Elm Architecture with Swift's `@Observable` pattern. It provides unidirectional data flow (`Action → Reduce → Mutation → State → View`) with minimal boilerplate.

**Key Components:**
- `@InnoFlow` macro: Generates `Reducer` protocol conformance and default `Effect = Never` if not defined
- `Store`: Main runtime that manages state and processes actions (uses `@Observable` and `@dynamicMemberLookup`)
- `Reducer` protocol: Defines `reduce()`, `mutate()`, and `handle()` methods
- `TestStore`: Testing utility from `InnoFlowTesting` module for comprehensive feature testing
- `@BindableField` macro: Marks state properties for two-way binding with SwiftUI

## Development Commands

### Building
```bash
swift build
```

### Testing
```bash
# Run all tests
swift test

# Run tests with code coverage
swift test --enable-code-coverage --parallel

# List available tests
swift test --list-tests

# Run a single test
swift test --filter InnoFlowTests.StoreTests/storeIncrement
```

### Building Examples
```bash
# CounterApp
cd Examples/CounterApp
xcodebuild -scheme CounterApp -destination 'platform=iOS Simulator,name=iPhone 16' clean build

# TodoApp
cd Examples/TodoApp
xcodebuild -scheme TodoApp -destination 'platform=iOS Simulator,name=iPhone 16' clean build
```

### Documentation
Documentation is built with DocC and hosted at: https://innosquad-mdd.github.io/InnoFlow/documentation/innoflow/

## Architecture

### Module Structure

```
InnoFlow/
├── Sources/
│   ├── InnoFlow/              # Core framework
│   │   ├── InnoFlow.swift     # @InnoFlow and @BindableField macros
│   │   ├── Store.swift        # Store and ScopedStore implementation
│   │   ├── Reducer.swift      # Reducer protocol
│   │   ├── Reduce.swift       # Reduce result type
│   │   └── EffectOutput.swift # Effect output types (.none, .single, .stream)
│   ├── InnoFlowMacros/        # Macro implementations (uses swift-syntax)
│   │   └── InnoFlowMacro.swift
│   └── InnoFlowTesting/       # Testing utilities
│       └── TestStore.swift
└── Tests/
    ├── InnoFlowTests/         # Core framework tests
    └── InnoFlowMacrosTests/   # Macro expansion tests
```

### Data Flow

1. **Action Dispatch**: View calls `store.send(action)`
2. **Reduce Phase**: `reduce(state:action:)` returns `Reduce<Mutation, Effect>`
3. **Mutation Phase**: Each mutation applied via `mutate(state:mutation:)`
4. **Effect Execution**: Effects handled asynchronously via `handle(effect:)` returning `EffectOutput<Action>`
5. **State Update**: Mutations update state, triggering view refresh via `@Observable`

### Effect Output Types

Effects can return:
- `.none` - Fire-and-forget (analytics, logging)
- `.single(action)` - Single action response (most common for API calls)
- `.stream(AsyncStream<Action>)` - Multiple actions over time (WebSocket, progress updates)
- `.actions(action1, action2, ...)` - Convenience for multiple sequential actions

### Macro Expansions

**`@InnoFlow` macro:**
- Adds `extension FeatureName: Reducer {}`
- If `Effect` type not defined: adds `typealias Effect = Never`
- If `Effect == Never` and no `handle()`: adds default `handle(effect:)` implementation

**`@BindableField` macro:**
- Transforms `@BindableField var step = 1` into:
  - Private storage: `private var _step_storage = BindableProperty(1)`
  - Computed property with getter/setter accessing `.value`
- Only properties marked with `@BindableField` can use `store.binding(_:send:)`

### Store Features

- **Dynamic Member Lookup**: `store.count` instead of `store.state.count`
- **Automatic Unwrapping**: `BindableProperty<T>` values auto-unwrapped via subscript
- **Thread Safety**: `@MainActor` on `Store`, thread-safe effect task storage using `Mutex`
- **Scoping**: `store.scope(state:action:)` creates `ScopedStore` for child views
- **Effect Lifecycle**: Effects auto-canceled on `deinit` or via `cancelAllEffects()`

## Testing Guidelines

### Using TestStore

```swift
@Test
func testIncrement() async {
    let store = TestStore(CounterFeature())

    // Send action and assert state change
    await store.send(.increment) {
        $0.count = 1
    }
}

@Test
func testAsyncEffect() async {
    let mockAPI = MockAPI(user: User(name: "Test"))
    let store = TestStore(UserFeature(api: mockAPI))

    // Action that triggers effect
    await store.send(.load) {
        $0.isLoading = true
    }

    // Receive action from effect
    await store.receive(._loaded(User(name: "Test"))) {
        $0.user = User(name: "Test")
        $0.isLoading = false
    }

    // Assert no unhandled actions
    await store.assertNoMoreActions()
}
```

**Important**:
- `TestStore` requires `State: Equatable`
- `receive()` requires `Action: Equatable`
- Always call `await store.assertNoMoreActions()` at end of async tests
- Use dependency injection for testing (pass mock services via init)

## Common Patterns

### Feature Without Effects
```swift
@InnoFlow
struct CounterFeature {
    struct State: Equatable { var count = 0 }
    enum Action { case increment }
    enum Mutation { case setCount(Int) }

    func reduce(state: State, action: Action) -> Reduce<Mutation, Never> {
        .mutation(.setCount(state.count + 1))
    }

    func mutate(state: inout State, mutation: Mutation) {
        switch mutation { case .setCount(let v): state.count = v }
    }
}
```

### Feature With Effects
```swift
@InnoFlow
struct UserFeature {
    struct State: Equatable { var user: User? }
    enum Action: Sendable { case load; case _loaded(User) }
    enum Mutation { case setUser(User?) }
    enum Effect: Sendable { case fetchUser }

    let api: APIClient

    func reduce(state: State, action: Action) -> Reduce<Mutation, Effect> {
        switch action {
        case .load: return .effect(.fetchUser)
        case ._loaded(let user): return .mutation(.setUser(user))
        }
    }

    func mutate(state: inout State, mutation: Mutation) {
        switch mutation { case .setUser(let u): state.user = u }
    }

    func handle(effect: Effect) async -> EffectOutput<Action> {
        switch effect {
        case .fetchUser:
            let user = try? await api.fetchUser()
            return .single(._loaded(user))
        }
    }
}
```

### Bindable Fields
```swift
struct State: Equatable {
    @BindableField var name = ""
    @BindableField var step = 1
    var count = 0  // Not bindable
}

// In view:
TextField("Name", text: store.binding(\.name, send: { .nameChanged($0) }))
Stepper("Step", value: store.binding(\.step, send: { .setStep($0) }))
```

## CI/CD

The project uses GitHub Actions (`.github/workflows/`):
- **ci.yml**: Runs tests, builds package, and builds example apps on macOS
- **cd.yml**: Handles releases and versioning
- **docs.yml**: Builds and deploys DocC documentation to GitHub Pages

## Platform Requirements

- iOS 18.0+ / macOS 15.0+ / tvOS 18.0+ / watchOS 11.0+
- Swift 6.0+
- Xcode 16.0+

## Dependencies

- `swift-syntax` 602.0.0+ (for macro implementation)
- `swift-docc-plugin` 1.0.0+ (for documentation)

## Naming Conventions

- **Internal Actions**: Prefix with `_` (e.g., `._loaded`, `._dataFetched`)
- **State**: Must conform to `Equatable`, optionally `DefaultInitializable` for `Store(feature)` init
- **Action/Effect**: Should be `Sendable` for concurrency safety
- **Mutation**: Pure state transformations only, no side effects
