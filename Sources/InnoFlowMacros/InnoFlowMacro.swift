// MARK: - InnoFlowMacro.swift
// InnoFlow - A Hybrid Architecture Framework for SwiftUI
// Copyright © 2025 InnoSquad. All rights reserved.

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - InnoFlow Macro Implementation

public struct InnoFlowMacro: ExtensionMacro, MemberMacro {
    
    // MARK: - Member Macro (adds Effect = Never if missing)
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Check if Effect is already defined
        let hasEffect = declaration.memberBlock.members.contains { member in
            if let enumDecl = member.decl.as(EnumDeclSyntax.self) {
                return enumDecl.name.text == "Effect"
            }
            if let typeAlias = member.decl.as(TypeAliasDeclSyntax.self) {
                return typeAlias.name.text == "Effect"
            }
            return false
        }
        
        // If Effect is not defined, add it as Never
        if !hasEffect {
            return [
                """
                typealias Effect = Never
                """
            ]
        }
        
        return []
    }
    
    // MARK: - Extension Macro (adds Reducer conformance)
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Get the type name
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroError.notAStruct
        }
        
        let typeName = structDecl.name.text
        
        // Check if Effect is defined (enum or typealias)
        let hasEffect = structDecl.memberBlock.members.contains { member in
            if let enumDecl = member.decl.as(EnumDeclSyntax.self) {
                return enumDecl.name.text == "Effect"
            }
            if let typeAlias = member.decl.as(TypeAliasDeclSyntax.self) {
                return typeAlias.name.text == "Effect"
            }
            return false
        }
        
        // Check if handle(effect:) is already defined
        let hasHandleMethod = structDecl.memberBlock.members.contains { member in
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                return funcDecl.name.text == "handle"
            }
            return false
        }
        
        // Build extension
        var extensionMembers: [String] = []
        
        // Add default handle(effect:) only if Effect is Never and handle isn't defined
        if !hasEffect && !hasHandleMethod {
            extensionMembers.append("""
                func handle(effect: Effect) async -> EffectOutput<Action> {
                    // Never type - unreachable
                }
            """)
        }
        
        // Create the extension
        let extensionDecl: ExtensionDeclSyntax
        
        if extensionMembers.isEmpty {
            extensionDecl = try ExtensionDeclSyntax("extension \(raw: typeName): Reducer {}")
        } else {
            let membersString = extensionMembers.joined(separator: "\n\n")
            extensionDecl = try ExtensionDeclSyntax("""
                extension \(raw: typeName): Reducer {
                    \(raw: membersString)
                }
                """)
        }
        
        return [extensionDecl]
    }
}

// MARK: - Errors

enum MacroError: Error, CustomStringConvertible {
    case notAStruct
    case missingState
    case missingAction
    
    var description: String {
        switch self {
        case .notAStruct:
            return "@InnoFlow can only be applied to structs"
        case .missingState:
            return "@InnoFlow requires a nested 'State' type"
        case .missingAction:
            return "@InnoFlow requires a nested 'Action' type"
        }
    }
}

// MARK: - Plugin Registration

@main
struct InnoFlowMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InnoFlowMacro.self,
        BindableFieldMacro.self
    ]
}


// MARK: - BindableField Macro Implementation

/// A macro that automatically wraps state properties in `BindableProperty` for type-safe binding.
///
/// Properties marked with `@BindableField` are automatically transformed:
/// - `@BindableField var step = 1` becomes a computed property backed by `BindableProperty<Int>`
/// - Only these properties can be used with `store.binding(_:send:)`
///
/// ## Example
/// ```swift
/// struct State: Equatable {
///     @BindableField var step = 1      // Automatically wrapped in BindableProperty
///     var count = 0                     // Not bindable - cannot use store.binding
/// }
/// ```
public struct BindableFieldMacro: PeerMacro, AccessorMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Get the variable declaration
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            return []
        }
        
        // Get the first binding
        guard let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return []
        }
        
        // Get type annotation and initializer
        let typeAnnotation = binding.typeAnnotation?.type
        let initializer = binding.initializer?.value
        
        // Determine the value type
        // We need either an explicit type annotation or an initializer to infer the type
        let valueType: String
        let initializerValue: String
        
        if let typeAnnotation = typeAnnotation {
            // Use explicit type annotation
            valueType = typeAnnotation.trimmedDescription
            if let initializer = initializer {
                initializerValue = "BindableProperty(\(initializer.trimmedDescription))"
            } else {
                // No initializer - try to use default initializer
                initializerValue = "BindableProperty<\(valueType)>(wrappedValue: \(valueType)())"
            }
        } else if let initializer = initializer {
            // No explicit type, but we have an initializer
            // We'll let Swift infer the type from the initializer
            // The storage will be: var _step_storage = BindableProperty(1)
            // And Swift will infer BindableProperty<Int>
            initializerValue = "BindableProperty(\(initializer.trimmedDescription))"
            // We'll create storage without explicit type and let Swift infer
            // The accessor will also work without explicit type
            valueType = "" // Empty means Swift will infer
        } else {
            // No type and no initializer - can't proceed
            return []
        }
        
        // Create storage variable name
        let storageName = "_\(identifier)_storage"
        
        // Use proper DeclSyntax construction to ensure macro coverage
        let finalDecl: DeclSyntax
        if !valueType.isEmpty {
            // Explicit type - use it
            finalDecl = DeclSyntax(
                """
                private var \(raw: storageName): BindableProperty<\(raw: valueType)> = \(raw: initializerValue)
                """
            )
        } else {
            // Type will be inferred from initializer
            finalDecl = DeclSyntax(
                """
                private var \(raw: storageName) = \(raw: initializerValue)
                """
            )
        }
        
        return [finalDecl]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        // Get the variable declaration
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            return []
        }
        
        // Get the first binding
        guard let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return []
        }
        
        // Storage variable name
        let storageName = "_\(identifier)_storage"
        
        // Create getter and setter
        // The getter returns the unwrapped value
        let getter = AccessorDeclSyntax(
            """
            get {
                \(raw: storageName).value
            }
            """
        )
        
        // The setter wraps the new value in BindableProperty
        // Swift will infer the type from the storage variable
        let setterBody = "\(storageName) = BindableProperty(newValue)"
        
        let setter = AccessorDeclSyntax(
            """
            set {
                \(raw: setterBody)
            }
            """
        )
        
        return [getter, setter]
    }
}

