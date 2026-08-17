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

/// freestanding declaration macro that generates `RAW_native()` and `init(RAW_native:)` for a `RAW_staticbuff` type
/// backed by a `BinaryFloatingPoint` type.
///
/// usage:
/// ```swift
/// @RAW_staticbuff(bytes:4) struct MyFloat:RAW_staticbuff {}
/// #RAW_staticbuff_binaryfloatingpoint_type<Float>()
/// ```
internal struct RAW_staticbuff_binaryfloatingpoint_type_macro:DeclarationMacro {
	internal static func expansion(of node:some SwiftSyntax.FreestandingMacroExpansionSyntax, in context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		// extract the generic type parameter
		guard let genericClause = node.genericArgumentClause, let type = genericClause.arguments.first?.argument else {
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
			self.init(RAW_staticbuff: &enc)
		}
		"""
		
		return [
			DeclSyntax(stringLiteral: nativeGetter),
			DeclSyntax(stringLiteral: nativeInit)
		]
	}
}
