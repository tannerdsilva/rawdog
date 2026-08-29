// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// freestanding declaration macro that generates `RAW_native()` and `init(RAW_native:)` for a `RAW_staticbuff` type
/// backed by a `FixedWidthInteger` type.
///
/// usage:
/// ```swift
/// @RAW_staticbuff(bytes:4) struct MyUInt32:RAW_staticbuff {}
/// #RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
/// ```
public struct RAW_staticbuff_fixedwidthinteger_type_macro:DeclarationMacro {
	public static func expansion(of node:some SwiftSyntax.FreestandingMacroExpansionSyntax, in context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard let genericClause = node.genericArgumentClause, let type = genericClause.arguments.first?.argument else {
			let diagnostic = Diagnostic(node:node, message:InternalMacroFailure(message:"expected a generic type parameter, e.g. <UInt32>"))
			context.diagnose(diagnostic)
			return []
		}
		guard let arg = node.arguments.first(where: { $0.label?.text == "bigEndian" }) else {
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
		
		return [
			DeclSyntax(stringLiteral: nativeGetter),
			DeclSyntax(stringLiteral: nativeInit)
		]
	}
}
