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

extension RAW_staticbuff_macro.ConcatMacro {
	internal final class RAW_staticbuff_concat_argument_validator:SyntaxVisitor {
		internal final class RAW_staticbuff_concat_declreferenceexpr_lister:SyntaxVisitor {
			internal var allDeclReferenceExprs:[DeclReferenceExprSyntax]? = nil
			internal override func visit(_ node:DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
				guard node.baseName.trimmedDescription != "self" else {
					return .skipChildren
				}
				if allDeclReferenceExprs == nil {
					allDeclReferenceExprs = [node]
				} else {
					allDeclReferenceExprs!.append(node)
				}
				return .skipChildren
			}
		}
		internal var rootLevelMemberAccessExprs:[MemberAccessExprSyntax]? = nil
		internal var allConcatTypes:[[DeclReferenceExprSyntax]]? = nil
		internal override func visit(_ node:LabeledExprSyntax) -> SyntaxVisitorContinueKind {
			guard let asMemberAccessExprSyntax = node.expression.as(MemberAccessExprSyntax.self), asMemberAccessExprSyntax.base != nil else {
				return .skipChildren
			}
			let declLister = RAW_staticbuff_concat_declreferenceexpr_lister(viewMode:.fixedUp)
			declLister.walk(asMemberAccessExprSyntax)
			guard let gotList = declLister.allDeclReferenceExprs else {
				return .skipChildren
			}
			if allConcatTypes == nil {
				allConcatTypes = [gotList]
				rootLevelMemberAccessExprs = [asMemberAccessExprSyntax]
			} else {
				allConcatTypes!.append(gotList)
				rootLevelMemberAccessExprs!.append(asMemberAccessExprSyntax)
			}
			return .skipChildren
		}
	}
	internal static func validateRAW_fixed_concat_arguments<T>(labeledExpression:LabeledExprListSyntax, context:SwiftSyntaxMacros.MacroExpansionContext, returning:T.Type = Optional<[[DeclReferenceExprSyntax]]>.self) -> [[DeclReferenceExprSyntax]]? {
		let concatTypesValidator = RAW_staticbuff_concat_argument_validator(viewMode:.fixedUp)
		concatTypesValidator.walk(labeledExpression)
		return concatTypesValidator.allConcatTypes
	}
	internal static func validateRAW_fixed_concat_arguments(labeledExpression:LabeledExprListSyntax, context:SwiftSyntaxMacros.MacroExpansionContext, returning:[MemberAccessExprSyntax].Type) -> [MemberAccessExprSyntax]? {
		let concatTypesValidator = RAW_staticbuff_concat_argument_validator(viewMode:.fixedUp)
		concatTypesValidator.walk(labeledExpression)
		return concatTypesValidator.rootLevelMemberAccessExprs
	}

	internal struct MismatchedConcatTypes:Swift.Error, SwiftDiagnostics.DiagnosticMessage {
		internal var message:String { "the concat types argument in the @RAW_staticbuff(concat:) macro does not match the concat types argument in this macro. expected \(expectedConcatTypes), found \(foundConcatTypes)." }
		internal let diagnosticID: SwiftDiagnostics.MessageID = SwiftDiagnostics.MessageID(domain:"\(String(describing: RAW_macros.RAW_fixed_protocol.ConcatMacro.self))", id: "\(String(describing: Self.self))")
		internal let severity: SwiftDiagnostics.DiagnosticSeverity = .error
		internal let expectedConcatTypes:[String]
		internal let foundConcatTypes:[String]
	}
	internal struct UnconfirmedConcatTypes:Swift.Error, SwiftDiagnostics.DiagnosticMessage {
		internal var message:String { "the concat types argument in the @RAW_staticbuff(concat:) macro could not be confirmed to match the concat types argument in this macro. expected \(expectedConcatTypes). implement the conformance of `RAW_staticbuff` on this member to resolve this error." }
		internal var diagnosticID: SwiftDiagnostics.MessageID = SwiftDiagnostics.MessageID(domain:"\(String(describing: RAW_macros.RAW_fixed_protocol.ConcatMacro.self))", id: "\(String(describing: Self.self))")
		internal let severity: SwiftDiagnostics.DiagnosticSeverity = .error
		internal let expectedConcatTypes:[String]
	}
}

extension RAW_staticbuff_macro.ConcatMacro: MemberMacro, ExtensionMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard case let .argumentList(args) = node.arguments else {
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

		guard let concatTypes = validateRAW_fixed_concat_arguments(labeledExpression:args, context:context, returning:[MemberAccessExprSyntax].self) else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"could not validate concat type arguments in @RAW_staticbuff(concat:) macro."))
			context.diagnose(diagnostic)
			return []
		}
		let buildAllConcatTypesString = concatTypes.map { $0.trimmedDescription }.joined(separator: ", ")
		
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

		let zeroTuple = "(" + concatTypes.map{ String($0.trimmedDescription.dropLast(5)) + ".RAW_staticbuff_zeroed()" }.joined(separator: ",") + ")"
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
		
		// Override compare function
		let concatTypesBases = concatTypes.map {
			guard let baseExpr = $0.base else {
				let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"could not extract base type from concat type reference.")); context.diagnose(diagnostic); return ""
			}
			return baseExpr.trimmedDescription
		}
		var rawCompareCode = ""
		for (i, baseType) in concatTypesBases.enumerated() {
			if i == 0 {
				rawCompareCode += "let b\(i) = \(baseType).RAW_compare(lhs_data: lhs_data, lhs_count: MemoryLayout<\(baseType)>.size, rhs_data: rhs_data, rhs_count: MemoryLayout<\(baseType)>.size)\n"
			} else {
				rawCompareCode +=
					"""
					lhs_var = lhs_var.advanced(by: MemoryLayout<\(concatTypesBases[i-1])>.size)
					rhs_var = rhs_var.advanced(by: MemoryLayout<\(concatTypesBases[i-1])>.size)\n
					"""
				rawCompareCode += "let b\(i) = \(baseType).RAW_compare(lhs_data: lhs_var, lhs_count: MemoryLayout<\(baseType)>.size, rhs_data: rhs_var, rhs_count: MemoryLayout<\(baseType)>.size)\n"
			}
			rawCompareCode += "if b\(i) != 0 { return b\(i) }"
		}
		let rawCompareFunction =
			"""
			public static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:Int, rhs_data:UnsafeRawPointer, rhs_count:Int) -> Int32 {
				var lhs_var = lhs_data; var rhs_var = rhs_data
				\(rawCompareCode)
				return 0
			}
			"""
		
		return [
			DeclSyntax(stringLiteral: "#RAW_fixed_type(concat:\(buildAllConcatTypesString))"),
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
			DeclSyntax(stringLiteral: rawCompareFunction),
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
