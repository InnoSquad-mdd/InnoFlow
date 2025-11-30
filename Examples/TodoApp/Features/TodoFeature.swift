// MARK: - TodoFeature.swift
// Todo 기능을 위한 Reducer

import Foundation
import InnoFlow

/// Todo 목록을 관리하는 Feature
@InnoFlow
struct TodoFeature {
    
    // MARK: - State
    
    struct State: Equatable, DefaultInitializable {
        var todos: [Todo] = []
        var isLoading = false
        var errorMessage: String?
        var filter: Filter = .all
        
        enum Filter: String, CaseIterable, Equatable {
            case all = "전체"
            case active = "미완료"
            case completed = "완료"
        }
        
        var filteredTodos: [Todo] {
            switch filter {
            case .all:
                return todos
            case .active:
                return todos.filter { !$0.isCompleted }
            case .completed:
                return todos.filter { $0.isCompleted }
            }
        }
        
        var completedCount: Int {
            todos.filter { $0.isCompleted }.count
        }
        
        var activeCount: Int {
            todos.filter { !$0.isCompleted }.count
        }
    }
    
    // MARK: - Action
    
    enum Action: Sendable {
        // UI Actions
        case loadTodos
        case addTodo(String)
        case toggleTodo(UUID)
        case deleteTodo(UUID)
        case deleteCompleted
        case setFilter(State.Filter)
        case editTodo(UUID, String)
        case dismissError
        
        // Internal Actions (from effects)
        case _todosLoaded([Todo])
        case _loadFailed(String)
    }
    
    // MARK: - Mutation
    
    enum Mutation {
        case setTodos([Todo])
        case addTodo(Todo)
        case toggleTodo(UUID)
        case deleteTodo(UUID)
        case deleteCompleted
        case setFilter(State.Filter)
        case editTodo(UUID, String)
        case setLoading(Bool)
        case setError(String?)
    }
    
    // MARK: - Effect
    
    enum Effect: Sendable {
        case loadTodos
        case saveTodos([Todo])
    }
    
    // MARK: - Dependencies
    
    let todoService: TodoServiceProtocol
    
    init(todoService: TodoServiceProtocol = TodoService.shared) {
        self.todoService = todoService
    }
    
    // MARK: - Reduce
    
    func reduce(state: State, action: Action) -> Reduce<Mutation, Effect> {
        switch action {
        // UI Actions
        case .loadTodos:
            return Reduce(
                mutations: [.setLoading(true), .setError(nil)],
                effects: [.loadTodos]
            )
            
        case .addTodo(let title):
            guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
                return .none
            }
            let newTodo = Todo(title: title)
            return Reduce(
                mutations: [.addTodo(newTodo)],
                effects: [.saveTodos(state.todos + [newTodo])]
            )
            
        case .toggleTodo(let id):
            var updatedTodos = state.todos
            if let index = updatedTodos.firstIndex(where: { $0.id == id }) {
                updatedTodos[index].isCompleted.toggle()
            }
            return Reduce(
                mutations: [.setTodos(updatedTodos)],
                effects: [.saveTodos(updatedTodos)]
            )
            
        case .deleteTodo(let id):
            let updatedTodos = state.todos.filter { $0.id != id }
            return Reduce(
                mutations: [.setTodos(updatedTodos)],
                effects: [.saveTodos(updatedTodos)]
            )
            
        case .deleteCompleted:
            let updatedTodos = state.todos.filter { !$0.isCompleted }
            return Reduce(
                mutations: [.setTodos(updatedTodos)],
                effects: [.saveTodos(updatedTodos)]
            )
            
        case .setFilter(let filter):
            return .mutation(.setFilter(filter))
            
        case .editTodo(let id, let newTitle):
            var updatedTodos = state.todos
            if let index = updatedTodos.firstIndex(where: { $0.id == id }) {
                updatedTodos[index].title = newTitle
            }
            return Reduce(
                mutations: [.setTodos(updatedTodos)],
                effects: [.saveTodos(updatedTodos)]
            )
            
        // Internal Actions
        case ._todosLoaded(let todos):
            return .mutations([.setTodos(todos), .setLoading(false), .setError(nil)])
            
        case ._loadFailed(let error):
            return .mutations([.setLoading(false), .setError(error)])
            
        case .dismissError:
            return .mutation(.setError(nil))
        }
    }
    
    // MARK: - Mutate
    
    func mutate(state: inout State, mutation: Mutation) {
        switch mutation {
        case .setTodos(let todos):
            state.todos = todos
            
        case .addTodo(let todo):
            state.todos.append(todo)
            
        case .toggleTodo(let id):
            if let index = state.todos.firstIndex(where: { $0.id == id }) {
                state.todos[index].isCompleted.toggle()
            }
            
        case .deleteTodo(let id):
            state.todos.removeAll { $0.id == id }
            
        case .deleteCompleted:
            state.todos.removeAll { $0.isCompleted }
            
        case .setFilter(let filter):
            state.filter = filter
            
        case .editTodo(let id, let newTitle):
            if let index = state.todos.firstIndex(where: { $0.id == id }) {
                state.todos[index].title = newTitle
            }
            
        case .setLoading(let isLoading):
            state.isLoading = isLoading
            
        case .setError(let error):
            state.errorMessage = error
        }
    }
    
    // MARK: - Handle Effects
    
    func handle(effect: Effect) async -> EffectOutput<Action> {
        switch effect {
        case .loadTodos:
            do {
                let todos = try await todoService.loadTodos()
                return .single(._todosLoaded(todos))
            } catch {
                return .single(._loadFailed(error.localizedDescription))
            }
            
        case .saveTodos(let todos):
            do {
                try await todoService.saveTodos(todos)
                return .none // Fire-and-forget
            } catch {
                // 저장 실패는 조용히 처리 (사용자에게 알릴 필요 없음)
                return .none
            }
        }
    }
}

