// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

fileprivate struct ExtraneousVariableDeclaration:DiagnosticMessage {
	fileprivate let message:String = "extraneous variable declaration found. instance variables are not supported in this configuration."
	fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_extraneous_variable_declaration")
	fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
	fileprivate struct FixItDiagnosticRemoveMe:FixItMessage {
		fileprivate let message:String = "remove this instance variable."
		fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_extraneous_variable_declaration")
	}
	fileprivate struct FixItDiagnosticConvertToStatic:FixItMessage {
		fileprivate let message:String = "convert this instance variable to a static variable."
		fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_extraneous_variable_declaration_convert_to_static")
	}
}

extension RAW_staticbuff_macro.BytesMacro: MemberMacro, ExtensionMacro {
	
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard case let .argumentList(args) = node.arguments, args.count == 1 else {
			// if there are not exactly one argument in the macro, we should not generate any code.
			return []
		}
		
		for member in declaration.memberBlock.members {
			guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
				continue
			}

			let isStatic = varDecl.modifiers.contains {
				$0.name.tokenKind == .keyword(.static)
			}
			
			func makeStatic(_ varDecl: VariableDeclSyntax) -> VariableDeclSyntax {
				let staticModifier = DeclModifierSyntax(
					leadingTrivia: .newline,
					name: .keyword(.static),
					trailingTrivia: .spaces(1)
				)
				var modifiedVarDecl = varDecl
				modifiedVarDecl.leadingTrivia = []
				
				let newModifiers = [staticModifier] + modifiedVarDecl.modifiers

				return modifiedVarDecl.with(\.modifiers, newModifiers)
			}
			
			guard isStatic else {
				// check if this is a computed property (has accessors) — these are allowed
				let isComputed = varDecl.bindings.contains { binding in
					binding.accessorBlock != nil
				}
				guard isComputed == false else {
					continue
				}
				context.diagnose(
					Diagnostic(
						node: Syntax(varDecl),
						message: ExtraneousVariableDeclaration(),
						fixIts: [
							FixIt(
								message: ExtraneousVariableDeclaration.FixItDiagnosticRemoveMe(),
								changes: [
									.replace(
										oldNode: Syntax(varDecl),
										newNode: Syntax(DeclSyntax(""))
									)
								]
							),
							FixIt(
								message: ExtraneousVariableDeclaration.FixItDiagnosticConvertToStatic(),
								changes: [
									.replace(
										oldNode: Syntax(varDecl),
										newNode: Syntax(makeStatic(varDecl))
									)
								]
							)
						]
					)
				)
				return []
			}
		}
		
		let numberOfBytes = RAW_macro_validators.validateRAW_fixed_byte_argument(labeledExpression:args.first!, context:context) ?? 0
		let rawStaticBuffArg = "_bytes"//context.makeUniqueName("RAW_static_buff_body_arg")
		
		let defaultInitializer =
			"""
			public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
				\(rawStaticBuffArg) = storetype
			}
			"""
		
		let getterFunction =
			"""
			@available(*, deprecated, message: "access the stored RAW_fixed_type via init(RAW_staticbuff:) instead")
			public consuming func RAW_staticbuff() -> RAW_fixed_type {
				return \(rawStaticBuffArg)
			}
			"""

		let zeroTuple = "(" + Array(repeating: "0", count: numberOfBytes).joined(separator: ",") + ")"
		let zeroFunction =
			"""
			@available(*, deprecated, message: "construct a zeroed instance from a zeroed RAW_fixed_type via init(RAW_staticbuff:) instead")
			public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
				\(zeroTuple)
			}
			"""

		let pointerInitializer =
			"""
			@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
			public init(RAW_staticbuff ptr: UnsafeRawPointer) {
				self = ptr.load(as: Self.self)
			}
			"""
		
		return [
			DeclSyntax(stringLiteral: "#RAW_fixed_type(bytes: \(numberOfBytes))"),
			DeclSyntax(stringLiteral: "var \(rawStaticBuffArg):RAW_fixed_type"),
			DeclSyntax(stringLiteral: """
public init?(RAW_decode bytes:UnsafeRawBufferPointer) {
    guard bytes.count == MemoryLayout<RAW_fixed_type>.size else { return nil }
    self = bytes.load(as: Self.self)
}
"""),
			DeclSyntax(stringLiteral: """
public borrowing func RAW_access_immutable<R, E>(_:UnsafeRawBufferPointer.Type, _ body:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
    return try withUnsafePointer(to: \(rawStaticBuffArg)) { (ptr:UnsafePointer<RAW_fixed_type>) throws(E) -> R in
        return try body(UnsafeRawBufferPointer(start:ptr, count: MemoryLayout<RAW_fixed_type>.size))
    }
}
"""),
			DeclSyntax(stringLiteral: """
public mutating func RAW_access_mutable<R, E>(_:UnsafeMutableRawBufferPointer.Type, _ body:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
    return try withUnsafeMutablePointer(to: &\(rawStaticBuffArg)) { (ptr:UnsafeMutablePointer<RAW_fixed_type>) throws(E) -> R in
        return try body(UnsafeMutableRawBufferPointer(start:ptr, count: MemoryLayout<RAW_fixed_type>.size))
    }
}
"""),
			DeclSyntax(stringLiteral: defaultInitializer),
			DeclSyntax(stringLiteral: getterFunction),
			DeclSyntax(stringLiteral: zeroFunction),
			DeclSyntax(stringLiteral: pointerInitializer),
		]
	}
	
	public static func expansion(
		of node: AttributeSyntax,
		attachedTo decl: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		let inherited = InheritedTypeListSyntax(
			protocols.enumerated().map { index, proto in
				let element = InheritedTypeSyntax(type: proto)

				// add comma AFTER every element except the last
				if index < protocols.count - 1 {
					return element.with(\.trailingComma, .commaToken())
				} else {
					return element
				}
			}
		)

		let ext = ExtensionDeclSyntax(
			extendedType: type,
			inheritanceClause: InheritanceClauseSyntax(
				inheritedTypes: inherited
			),
			memberBlock: MemberBlockSyntax(members: [])
		)

		return [ext]
	}
}
