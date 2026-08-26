// MARK: - InnoFlowCasePathIgnoredMacro.swift
// InnoFlow - A Hybrid Architecture Framework for SwiftUI
// Copyright © 2025 InnoSquad. All rights reserved.

import SwiftDiagnostics
public import SwiftSyntax
public import SwiftSyntaxMacros

public struct InnoFlowCasePathIgnoredMacro: PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard declaration.is(EnumCaseDeclSyntax.self) else {
      context.diagnose(
        Diagnostic(
          node: Syntax(node),
          message: InnoFlowCasePathIgnoredMessage.requiresEnumCase
        )
      )
      return []
    }

    return []
  }
}

enum InnoFlowCasePathIgnoredMessage: DiagnosticMessage {
  case requiresEnumCase

  var message: String {
    "@InnoFlowCasePathIgnored can only be attached to an enum case"
  }

  var diagnosticID: MessageID {
    .init(domain: "InnoFlowMacro", id: "CasePathIgnoredRequiresEnumCase")
  }

  var severity: DiagnosticSeverity {
    .error
  }
}
