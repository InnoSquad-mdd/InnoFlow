import SwiftUI
import InnoFlow
import Foundation

// MARK: - Todo Model

struct Todo: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}

// MARK: - TodoService

protocol TodoServiceProtocol: Sendable {
    func loadTodos() async throws -> [Todo]
    func saveTodos(_ todos: [Todo]) async throws
}

actor TodoService: TodoServiceProtocol {
    static let shared = TodoService()
    
    private let key = "saved_todos"
    
    func loadTodos() async throws -> [Todo] {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Todo].self, from: data)
    }
    
    func saveTodos(_ todos: [Todo]) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(todos)
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - TodoFeature

@Reducer
struct TodoFeature {
    
    struct State: Equatable, DefaultInitializable {
        var todos: [Todo] = []
        var isLoading = false
        var errorMessage: String?
        @BindableField var filter = Filter.all
        
        enum Filter: String, CaseIterable, Equatable, Sendable {
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
    
    enum Action: Sendable {
        case loadTodos
        case addTodo(String)
        case toggleTodo(UUID)
        case deleteTodo(UUID)
        case deleteCompleted
        case setFilter(State.Filter)
        case editTodo(UUID, String)
        case dismissError
        case _todosLoaded([Todo])
        case _loadFailed(String)
    }
    
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
    
    enum Effect: Sendable {
        case loadTodos
        case saveTodos([Todo])
    }
    
    let todoService: TodoServiceProtocol
    
    init(todoService: TodoServiceProtocol = TodoService.shared) {
        self.todoService = todoService
    }
    
    func reduce(state: State, action: Action) -> Reduce<Mutation, Effect> {
        switch action {
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
            
        case ._todosLoaded(let todos):
            return .mutations([.setTodos(todos), .setLoading(false), .setError(nil)])
            
        case ._loadFailed(let error):
            return .mutations([.setLoading(false), .setError(error)])
            
        case .dismissError:
            return .mutation(.setError(nil))
        }
    }
    
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
                return .none
            } catch {
                return .none
            }
        }
    }
}

// MARK: - TodoRowView

struct TodoRowView: View {
    let todo: Todo
    let onToggle: () -> Void
    let onEdit: (String) -> Void
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(todo.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            if isEditing {
                TextField("", text: $editedTitle)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        saveEdit()
                    }
                    .onAppear {
                        editedTitle = todo.title
                        isTextFieldFocused = true
                    }
            } else {
                Text(todo.title)
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .onTapGesture(count: 2) {
                        startEditing()
                    }
            }
            
            Spacer()
            
            if !isEditing {
                Menu {
                    Button("편집") {
                        startEditing()
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func startEditing() {
        isEditing = true
        editedTitle = todo.title
    }
    
    private func saveEdit() {
        if !editedTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            onEdit(editedTitle)
        }
        isEditing = false
    }
}

// MARK: - TodoListView

struct TodoListView: View {
    @State private var store = Store(TodoFeature())
    @State private var newTodoTitle = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            filterView
            
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.filteredTodos.isEmpty {
                emptyStateView
            } else {
                todoListView
            }
            
            inputView
        }
        .navigationTitle("할 일")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if store.completedCount > 0 {
                    Button("완료 삭제") {
                        store.send(.deleteCompleted)
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .task {
            store.send(.loadTodos)
        }
        .alert("오류", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { _ in }
        )) {
            Button("확인", role: .cancel) {
                store.send(.dismissError)
            }
        } message: {
            if let error = store.errorMessage {
                Text(error)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("전체: \(store.todos.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("완료: \(store.completedCount)")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Text("미완료: \(store.activeCount)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }
    
    private var filterView: some View {
        Picker("필터", selection: store.binding(\.filter, send: { .setFilter($0) })) {
            ForEach(TodoFeature.State.Filter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private var todoListView: some View {
        List {
            ForEach(store.filteredTodos) { todo in
                TodoRowView(todo: todo) {
                    store.send(.toggleTodo(todo.id))
                } onEdit: { newTitle in
                    store.send(.editTodo(todo.id, newTitle))
                } onDelete: {
                    store.send(.deleteTodo(todo.id))
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(store.filter == .all ? "할 일이 없습니다" : "\(store.filter.rawValue) 항목이 없습니다")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var inputView: some View {
        HStack {
            TextField("새 할 일 추가", text: $newTodoTitle)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .onSubmit {
                    addTodo()
                }
            
            Button(action: addTodo) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(newTodoTitle.isEmpty ? .gray : .blue)
            }
            .disabled(newTodoTitle.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func addTodo() {
        guard !newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        store.send(.addTodo(newTodoTitle))
        newTodoTitle = ""
        isTextFieldFocused = false
    }
}

// MARK: - ContentView

public struct ContentView: View {
    public var body: some View {
        NavigationStack {
            TodoListView()
        }
    }
    
    public init() {}
}
