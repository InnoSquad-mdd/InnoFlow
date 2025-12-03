# Repository Guidelines

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

## Project Structure & Module Organization
- Swift Package with targets in `Package.swift`: core `InnoFlow`, macro implementation `InnoFlowMacros`, and testing utilities `InnoFlowTesting`.
- Source code lives in `Sources/InnoFlow` (Store, Reducer, Reduce, macros), macros in `Sources/InnoFlowMacros`, and testing helpers in `Sources/InnoFlowTesting`.
- Tests use Swift Testing under `Tests/InnoFlowTests` and `Tests/InnoFlowMacrosTests`.
- Example apps sit in `Examples/CounterApp` and `Examples/TodoApp` for integration references.
- Generated DocC output and build artifacts are staged under `docs-build/` (do not edit by hand).

## Build, Test, and Development Commands
- `swift build` — compile all package targets.
- `swift test` — run the full test suite; add `--enable-code-coverage --parallel` for coverage and speed, or `--filter InnoFlowTests.StoreTests/storeIncrement` for a single case.
- `swift package generate-documentation --target InnoFlow` — regenerate DocC locally (output goes to `.build`). 
- Example builds: `cd Examples/CounterApp && xcodebuild -scheme CounterApp -destination 'platform=iOS Simulator,name=iPhone 16' clean build` (similar for `TodoApp`).

## Coding Style & Naming Conventions
- Follow Swift API Design Guidelines; use 4-space indentation and keep public APIs documented with `///`.
- Prefer value semantics and explicit types; keep reducers small and focused.
- Actions that are internal to the reducer should be prefixed with `_` (e.g., `._loaded`) and conform to `Sendable` when effects are async.
- Name test helpers and fixtures descriptively; avoid abbreviations in public symbols.
- Run SwiftFormat/SwiftLint equivalents if introduced in future; currently rely on compiler warnings and tests.

## Testing Guidelines
- Framework: Swift Testing (`import Testing`). Use `@Suite` and `@Test("description")` names that read as sentences.
- `TestStore` requires `State: Equatable`; `receive` assertions require `Action: Equatable`. Call `await store.assertNoMoreActions()` at the end of async tests.
- Cover both reducer logic and macro expansions (see `Tests/InnoFlowMacrosTests`). Favor deterministic mocks for effects.
- Use `swift test --enable-code-coverage` before release PRs; keep tests colocated with the feature under test.

## Commit & Pull Request Guidelines
- Commit messages mirror existing history: present-tense, sentence-style summaries (e.g., `Simplifies release note generation`). Squash only when necessary.
- PRs should describe the change, link related issues, and note any docs or changelog updates (`CHANGELOG.md`, `README.md`) you touched.
- Include commands run (`swift test`, doc generation, example builds) and screenshots for UI demo changes in `Examples/`.
- Ensure no generated artifacts from `docs-build/` or `.build/` are committed unless explicitly requested.
