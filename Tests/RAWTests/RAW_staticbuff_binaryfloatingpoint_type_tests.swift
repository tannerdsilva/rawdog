import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

@Suite("Macro: #RAW_staticbuff_binaryfloatingpoint_type", .serialized)
struct RAW_staticbuff_binaryfloatingpoint_type_tests {
	@Test("Float - generates RAW_native() and init(RAW_native:)")
	func testBinaryFloatingPointFloat() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_binaryfloatingpoint_type<Float>()
			""",
			expandedSource:
			"""
			public func RAW_native() -> Float {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Float>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return Float(bitPattern: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt32.self))
				}
			}
			public init(RAW_native native: Float) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bitPattern
				self.init(RAW_staticbuff: withUnsafeBytes(of: &enc) { raw in
					return raw.loadUnaligned(as: RAW_fixed_type.self)
				})
			}
			""",
			macroSpecs:["RAW_staticbuff_binaryfloatingpoint_type": MacroSpec(type: RAW_staticbuff_binaryfloatingpoint_type_macro.self)],
			indentationWidth:.tabs(1),
			failureHandler: { (testFailureSpec:TestFailureSpec) in
				Issue.record(
					TestFailureSpecError(
						message:testFailureSpec.message,
						path:testFailureSpec.location.filePath,
						line:testFailureSpec.location.line,
						column:testFailureSpec.location.column
					)
				)
			}
		)
	}

	@Test("Double - generates RAW_native() and init(RAW_native:)")
	func testBinaryFloatingPointDouble() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_binaryfloatingpoint_type<Double>()
			""",
			expandedSource:
			"""
			public func RAW_native() -> Double {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Double>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return Double(bitPattern: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt64.self))
				}
			}
			public init(RAW_native native: Double) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bitPattern
				self.init(RAW_staticbuff: withUnsafeBytes(of: &enc) { raw in
					return raw.loadUnaligned(as: RAW_fixed_type.self)
				})
			}
			""",
			macroSpecs:["RAW_staticbuff_binaryfloatingpoint_type": MacroSpec(type: RAW_staticbuff_binaryfloatingpoint_type_macro.self)],
			indentationWidth:.tabs(1),
			failureHandler: { (testFailureSpec:TestFailureSpec) in
				Issue.record(
					TestFailureSpecError(
						message:testFailureSpec.message,
						path:testFailureSpec.location.filePath,
						line:testFailureSpec.location.line,
						column:testFailureSpec.location.column
					)
				)
			}
		)
	}

	@Test("Float16 - generates RAW_native() and init(RAW_native:)")
	func testBinaryFloatingPointFloat16() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_binaryfloatingpoint_type<Float16>()
			""",
			expandedSource:
			"""
			public func RAW_native() -> Float16 {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Float16>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return Float16(bitPattern: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt16.self))
				}
			}
			public init(RAW_native native: Float16) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bitPattern
				self.init(RAW_staticbuff: withUnsafeBytes(of: &enc) { raw in
					return raw.loadUnaligned(as: RAW_fixed_type.self)
				})
			}
			""",
			macroSpecs:["RAW_staticbuff_binaryfloatingpoint_type": MacroSpec(type: RAW_staticbuff_binaryfloatingpoint_type_macro.self)],
			indentationWidth:.tabs(1),
			failureHandler: { (testFailureSpec:TestFailureSpec) in
				Issue.record(
					TestFailureSpecError(
						message:testFailureSpec.message,
						path:testFailureSpec.location.filePath,
						line:testFailureSpec.location.line,
						column:testFailureSpec.location.column
					)
				)
			}
		)
	}

	@Test("unsupported type emits diagnostic")
	func testBinaryFloatingPointUnsupportedType() throws {
		let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"InternalMacroFailure"), message:"unsupported BinaryFloatingPoint type: Float80. Supported types: Float, Double, Float16", line:1, column:1, severity:.error)
		assertMacroExpansion(
			"""
			#RAW_staticbuff_binaryfloatingpoint_type<Float80>()
			""",
			expandedSource:
			"""
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_staticbuff_binaryfloatingpoint_type": MacroSpec(type: RAW_staticbuff_binaryfloatingpoint_type_macro.self)],
			indentationWidth:.tabs(1),
			failureHandler: { (testFailureSpec:TestFailureSpec) in
				Issue.record(
					TestFailureSpecError(
						message:testFailureSpec.message,
						path:testFailureSpec.location.filePath,
						line:testFailureSpec.location.line,
						column:testFailureSpec.location.column
					)
				)
			}
		)
	}

	@Test("missing generic type parameter emits diagnostic")
	func testBinaryFloatingPointMissingGeneric() throws {
		let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"InternalMacroFailure"), message:"expected a generic type parameter, e.g. <Float>", line:1, column:1, severity:.error)
		assertMacroExpansion(
			"""
			#RAW_staticbuff_binaryfloatingpoint_type()
			""",
			expandedSource:
			"""
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_staticbuff_binaryfloatingpoint_type": MacroSpec(type: RAW_staticbuff_binaryfloatingpoint_type_macro.self)],
			indentationWidth:.tabs(1),
			failureHandler: { (testFailureSpec:TestFailureSpec) in
				Issue.record(
					TestFailureSpecError(
						message:testFailureSpec.message,
						path:testFailureSpec.location.filePath,
						line:testFailureSpec.location.line,
						column:testFailureSpec.location.column
					)
				)
			}
		)
	}
}

