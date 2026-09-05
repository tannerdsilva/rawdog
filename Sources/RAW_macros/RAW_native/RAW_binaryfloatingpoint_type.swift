// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// maps BinaryFloatingPoint types to their bit pattern integer types
fileprivate let typeBitpatternTypes:[String:String] = [
	"Double":"UInt64",
	"Float":"UInt32",
	"Float16":"UInt16"
]

/// maps BinaryFloatingPoint types to their `bitPattern` property name
fileprivate let typeBitNames:[String:String] = [
	"Double":"bitPattern",
	"Float":"bitPattern",
	"Float16":"bitPattern"
]

/// attached member macro that generates `RAW_native()` and `init(RAW_native:)` for a `RAW_staticbuff` type
/// backed by a `BinaryFloatingPoint` type, and attaches the `RAW_encoded_binaryfloatingpoint` conformance.
///
/// usage:
/// ```swift
/// @RAW_staticbuff(bytes:4)
/// @RAW_staticbuff_binaryfloatingpoint_type<Float>()
/// struct MyFloat:RAW_staticbuff {}
/// ```
internal struct RAW_staticbuff_binaryfloatingpoint_type_macro:MemberMacro, ExtensionMacro {
	internal static func expansion(of node:AttributeSyntax, providingMembersOf declaration:some DeclGroupSyntax, conformingTo protocols:[TypeSyntax], in context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		// extract the generic type parameter
		guard let genericClause = node.attributeName.as(IdentifierTypeSyntax.self)?.genericArgumentClause, let type = genericClause.arguments.first?.argument else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected a generic type parameter, e.g. <Float>"))
			context.diagnose(diagnostic)
			return []
		}
		let typeName = type.trimmedDescription
		
		// determine the bit pattern type
		guard let bitPatternType = typeBitpatternTypes[typeName], let nativeTranslatorName = typeBitNames[typeName] else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"unsupported BinaryFloatingPoint type: \(typeName). Supported types: Float, Double, Float16"))
			context.diagnose(diagnostic)
			return []
		}
		
		// determine load function based on size
		let loadFuncName = (bitPatternType == "UInt8") ? "load" : "loadUnaligned"
		
		let nativeGetter = """
		public func RAW_native() -> \(typeName) {
			#if DEBUG
			assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
			assert(MemoryLayout<\(typeName)>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
			#endif
			return withUnsafePointer(to: self) { selfPtr in
				return \(typeName)(\(nativeTranslatorName): UnsafeRawPointer(selfPtr).\(loadFuncName)(as: \(bitPatternType).self))
			}
		}
		"""
		
		let nativeInit = """
		public init(RAW_native native: \(typeName)) {
			#if DEBUG
			assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
			#endif
			var enc = native.\(nativeTranslatorName)
			self.init(RAW_staticbuff: withUnsafeBytes(of: &enc) { raw in
				return raw.loadUnaligned(as: RAW_fixed_type.self)
			})
		}
		"""
		
		// numeric compare over the native value, via its bit pattern. this is the
		// v21 behavior restored verbatim: binary-floating-point types force their
		// own ordering, comparing decoded values instead of the memcmp default.
		let compareFunction = """
		public static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
			let lhs = \(typeName)(\(nativeTranslatorName): lhs_data.\(loadFuncName)(as: \(bitPatternType).self))
			let rhs = \(typeName)(\(nativeTranslatorName): rhs_data.\(loadFuncName)(as: \(bitPatternType).self))
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
		guard let genericClause = node.attributeName.as(IdentifierTypeSyntax.self)?.genericArgumentClause, let type = genericClause.arguments.first?.argument else {
			return false
		}
		let typeName = type.trimmedDescription
		guard typeBitpatternTypes[typeName] != nil, typeBitNames[typeName] != nil else {
			return false
		}
		return true
	}

	internal static func expansion(
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
