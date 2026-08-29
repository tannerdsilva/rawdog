import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

@Suite("Macro: #RAW_staticbuff_fixedwidthinteger_type", .serialized)
struct RAW_staticbuff_fixedwidthinteger_type_tests {
	@Test("UInt32(bigEndian:true) - generates RAW_native() and init(RAW_native:)")
	func testFixedWidthIntegerUInt32BigEndian() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:true)
			""",
			expandedSource:
			"""
			public func RAW_native() -> UInt32 {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<UInt32>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return UInt32(bigEndian: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt32.self))
				}
			}
			public init(RAW_native native: UInt32) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bigEndian
				self.init(RAW_staticbuff: withUnsafeBytes(of: &enc) { raw in
					return raw.loadUnaligned(as: RAW_fixed_type.self)
				})
			}
			""",
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

	@Test("UInt32(bigEndian:false) - uses littleEndian")
	func testFixedWidthIntegerUInt32LittleEndian() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:false)
			""",
			expandedSource:
			"""
			public func RAW_native() -> UInt32 {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<UInt32>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return UInt32(littleEndian: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt32.self))
				}
			}
			public init(RAW_native native: UInt32) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.littleEndian
				self.init(RAW_staticbuff: withUnsafeBytes(of: &enc) { raw in
					return raw.loadUnaligned(as: RAW_fixed_type.self)
				})
			}
			""",
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

	@Test("UInt8(bigEndian:true) - 1-byte uses `load` instead of `loadUnaligned`")
	func testFixedWidthIntegerUInt8() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt8>(bigEndian:true)
			""",
			expandedSource:
			"""
			public func RAW_native() -> UInt8 {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<UInt8>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return UInt8(bigEndian: UnsafeRawPointer(selfPtr).load(as: UInt8.self))
				}
			}
			public init(RAW_native native: UInt8) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bigEndian
				self.init(RAW_staticbuff: withUnsafeBytes(of: &enc) { raw in
					return raw.loadUnaligned(as: RAW_fixed_type.self)
				})
			}
			""",
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

	@Test("UInt64(bigEndian:true) - 8-byte uses loadUnaligned")
	func testFixedWidthIntegerUInt64() throws {
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt64>(bigEndian:true)
			""",
			expandedSource:
			"""
			public func RAW_native() -> UInt64 {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<UInt64>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to: self) { selfPtr in
					return UInt64(bigEndian: UnsafeRawPointer(selfPtr).loadUnaligned(as: UInt64.self))
				}
			}
			public init(RAW_native native: UInt64) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_fixed_type>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.bigEndian
				self.init(RAW_staticbuff: withUnsafeBytes(of: &enc) { raw in
					return raw.loadUnaligned(as: RAW_fixed_type.self)
				})
			}
			""",
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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
	func testFixedWidthIntegerMissingGeneric() throws {
		let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"InternalMacroFailure"), message:"expected a generic type parameter, e.g. <UInt32>", line:1, column:1, severity:.error)
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type(bigEndian:true)
			""",
			expandedSource:
			"""
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

	@Test("missing bigEndian argument emits diagnostic")
	func testFixedWidthIntegerMissingBigEndian() throws {
		let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"InternalMacroFailure"), message:"expected a 'bigEndian' argument, e.g. bigEndian:true", line:1, column:1, severity:.error)
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt32>()
			""",
			expandedSource:
			"""
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

	@Test("non-boolean bigEndian value emits diagnostic")
	func testFixedWidthIntegerNonBoolBigEndian() throws {
		let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"InternalMacroFailure"), message:"the 'bigEndian' argument must be a boolean literal (true or false)", line:1, column:48, severity:.error)
		assertMacroExpansion(
			"""
			#RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian:42)
			""",
			expandedSource:
			"""
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_staticbuff_fixedwidthinteger_type": MacroSpec(type: RAW_staticbuff_fixedwidthinteger_type_macro.self)],
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

