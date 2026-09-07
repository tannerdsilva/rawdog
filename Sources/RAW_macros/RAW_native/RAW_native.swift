// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// attached member macro that generates `RAW_native()` and `init(RAW_native:)` for a `RAW_staticbuff` type
/// backed by a `FixedWidthInteger` type, and attaches the `RAW_encoded_fixedwidthinteger` conformance.
///
/// usage:
/// ```swift
/// @RAW_staticbuff(bytes:4)
/// @RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
/// struct MyUInt32:RAW_staticbuff {}
/// ```
public struct RAW_staticbuff_fixedwidthinteger_type_macro:MemberMacro, ExtensionMacro {
	public static func expansion(of node:AttributeSyntax, providingMembersOf declaration:some DeclGroupSyntax, conformingTo protocols:[TypeSyntax], in context:some MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard let genericClause = node.attributeName.as(IdentifierTypeSyntax.self)?.genericArgumentClause, let type = genericClause.arguments.first?.argument else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected a generic type parameter, e.g. <UInt32>"))
			context.diagnose(diagnostic)
			return []
		}
		guard let args = node.arguments?.as(LabeledExprListSyntax.self), let arg = args.first(where: { $0.label?.text == "bigEndian" }) else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected a 'bigEndian' argument, e.g. bigEndian:true"))
			context.diagnose(diagnostic)
			return []
		}
		guard let boolExpr = arg.expression.as(BooleanLiteralExprSyntax.self) else {
			let diagnostic = Diagnostic(node:arg, message:InternalMacroFailure(message:"the 'bigEndian' argument must be a boolean literal (true or false)"))
			context.diagnose(diagnostic)
			return []
		}
		let endianText = boolExpr.literal.text == "true" ? "bigEndian" : "littleEndian"
		let typeName = type.trimmedDescription
		let loadFuncName = typeName == "UInt8" || typeName == "Int8" ? "load" : "loadUnaligned"
		
		let nativeGetter = """
		public func RAW_native() -> \(typeName) {
			#if DEBUG
			assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
			assert(MemoryLayout<\(typeName)>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
			#endif
			return withUnsafePointer(to: self) { selfPtr in
				return \(typeName)(\(endianText): UnsafeRawPointer(selfPtr).\(loadFuncName)(as: \(typeName).self))
			}
		}
		"""
		
		let nativeInit = """
		public init(RAW_native native: \(typeName)) {
			#if DEBUG
			assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
			#endif
			var enc = native.\(endianText)
			self.init(RAW_staticbuff: withUnsafeBytes(of: &enc) { raw in
				return raw.loadUnaligned(as: RAW_fixed_type.self)
			})
		}
		"""
		
		// numeric compare over the native value, translated through the configured
		// endianness. this is the v21 behavior restored verbatim: fixed-width
		// integers force their own ordering, so big- and little-endian storage
		// both order numerically (the memcmp default would compare physical bytes).
		let compareFunction = """
		public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
			let lhs = \(typeName)(\(endianText): lhs_data.\(loadFuncName)(as: \(typeName).self))
			let rhs = \(typeName)(\(endianText): rhs_data.\(loadFuncName)(as: \(typeName).self))
			if lhs < rhs {
				return -1
			} else if lhs > rhs {
				return 1
			} else {
				return 0
			}
		}
		"""
		
		return [
			DeclSyntax(stringLiteral: compareFunction),
			DeclSyntax(stringLiteral: nativeGetter),
			DeclSyntax(stringLiteral: nativeInit)
		]
	}

	/// returns true when the attribute arguments are well-formed enough to generate members.
	/// the member role emits the user-facing diagnostics; the extension role uses this to
	/// avoid injecting a conformance the type cannot satisfy after a failed expansion.
	fileprivate static func argumentsAreWellFormed(_ node:AttributeSyntax) -> Bool {
		guard let genericClause = node.attributeName.as(IdentifierTypeSyntax.self)?.genericArgumentClause, let type = genericClause.arguments.first?.argument, type.trimmedDescription.isEmpty == false else {
			return false
		}
		guard let args = node.arguments?.as(LabeledExprListSyntax.self), let arg = args.first(where: { $0.label?.text == "bigEndian" }), let boolExpr = arg.expression.as(BooleanLiteralExprSyntax.self), boolExpr.literal.text == "true" || boolExpr.literal.text == "false" else {
			return false
		}
		return true
	}

	public static func expansion(
		of node: AttributeSyntax,
		attachedTo decl: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo protocols: [TypeSyntax],
		in context: some SwiftSyntaxMacros.MacroExpansionContext
	) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		// skip entirely when the conformance is already declared in the type's own
		// inheritance clause (the compiler then passes an empty conformingTo list)
		guard argumentsAreWellFormed(node), protocols.isEmpty == false else {
			return []
		}
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
