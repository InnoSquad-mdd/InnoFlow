# InnoFlow Sample Apps

Real-world example applications using InnoFlow.

## 📱 Available Sample Apps

### 1. CounterApp

**Simplest Example** - A basic counter app without Effects

- Increment/Decrement counter
- Reset counter
- Set increment step

**Learning Points**:
- Basic usage of `@InnoFlow` macro
- Implementing Features without Effects
- Using `@dynamicMemberLookup`

[Learn more →](./CounterApp/README.md)

---

### 2. TodoApp

**Real-world Example** - Todo management app with async Effects

- Todo CRUD (Create/Read/Update/Delete)
- Toggle completion status
- Filtering (All/Active/Completed)
- Data persistence (UserDefaults)
- Async data loading

**Learning Points**:
- Handling async Effects
- Dependency injection pattern
- Protocol-based service design
- Applying SOLID principles

[Learn more →](./TodoApp/README.md)

---

## 🎯 Features of Each Sample App

### CounterApp
```
Complexity: ⭐
Effect Usage: ❌
Dependency Injection: ❌
```

### TodoApp
```
Complexity: ⭐⭐⭐
Effect Usage: ✅
Dependency Injection: ✅
```

---

## 🚀 How to Run

Each sample app can be run independently:

1. Open the project in Xcode
2. Select the target of the desired sample app
3. Run on simulator or physical device

---

## 📚 Recommended Learning Order

1. Start with **CounterApp** to understand basic concepts
2. Learn practical patterns with **TodoApp**
3. Apply to your own app

---

## 🔍 Code Analysis

Each sample app follows SOLID principles and demonstrates InnoFlow best practices:

- ✅ Single Responsibility: Each component has a clear responsibility
- ✅ Open/Closed: Protocol-based extensible design
- ✅ Liskov Substitution: Protocol implementations are interchangeable
- ✅ Interface Segregation: Minimal interfaces
- ✅ Dependency Inversion: Depend on protocols

---

**Need more examples?** Please open an issue!
