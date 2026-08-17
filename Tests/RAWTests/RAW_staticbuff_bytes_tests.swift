import Testing
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import SwiftDiagnostics
import RAW
@testable import RAW_macros

@Suite("Macro: @RAW_staticbuff(bytes:)", .serialized)
struct RAW_staticbuff_bytes_tests {
	@Test("bytes:5 - generates member + extension")
	func testStaticbuffBytesValid() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 5)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {

				#RAW_fixed_type(bytes: 5)

				var _bytes: RAW_fixed_type

				public init?(RAW_decode bytes: UnsafeRawBufferPointer) {
				    guard bytes.count == MemoryLayout<RAW_fixed_type>.size else {
				    	return nil
				    }
				    self = bytes.load(as: Self.self)
				}

				public borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ body: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafePointer(to: _bytes) { (ptr: UnsafePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafeMutablePointer(to: &_bytes) { (ptr: UnsafeMutablePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeMutableRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(0, 0, 0, 0, 0)
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
			}
			""",
			macroSpecs:["RAW_staticbuff": MacroSpec(type: RAW_staticbuff_macro.BytesMacro.self, conformances:["RAW_staticbuff", "RAW_accessible", "RAW_decodable", "RAW_encodable", "RAW_comparable"])],
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

	@Test("bytes:1 - single byte type")
	func testStaticbuffBytesSingle() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 1)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {

				#RAW_fixed_type(bytes: 1)

				var _bytes: RAW_fixed_type

				public init?(RAW_decode bytes: UnsafeRawBufferPointer) {
				    guard bytes.count == MemoryLayout<RAW_fixed_type>.size else {
				    	return nil
				    }
				    self = bytes.load(as: Self.self)
				}

				public borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ body: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafePointer(to: _bytes) { (ptr: UnsafePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafeMutablePointer(to: &_bytes) { (ptr: UnsafeMutablePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeMutableRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(0)
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
			}
			""",
			macroSpecs:["RAW_staticbuff": MacroSpec(type: RAW_staticbuff_macro.BytesMacro.self, conformances:["RAW_staticbuff", "RAW_accessible", "RAW_decodable", "RAW_encodable", "RAW_comparable"])],
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

	@Test("bytes:16 - sixteen byte type")
	func testStaticbuffBytesSixteen() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 16)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {

				#RAW_fixed_type(bytes: 16)

				var _bytes: RAW_fixed_type

				public init?(RAW_decode bytes: UnsafeRawBufferPointer) {
				    guard bytes.count == MemoryLayout<RAW_fixed_type>.size else {
				    	return nil
				    }
				    self = bytes.load(as: Self.self)
				}

				public borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ body: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafePointer(to: _bytes) { (ptr: UnsafePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafeMutablePointer(to: &_bytes) { (ptr: UnsafeMutablePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeMutableRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
			}
			""",
			macroSpecs:["RAW_staticbuff": MacroSpec(type: RAW_staticbuff_macro.BytesMacro.self, conformances:["RAW_staticbuff", "RAW_accessible", "RAW_decodable", "RAW_encodable", "RAW_comparable"])],
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

	@Test("extraneous instance variable emits diagnostic")
	func testStaticbuffBytesExtraneousVar() throws {
let expectedDiagnostic = DiagnosticSpec(id:MessageID(domain:"RAW_macros", id:"staticbuff_extraneous_variable_declaration"), message:"extraneous variable declaration found. instance variables are not supported in this configuration.", line:3, column:2, severity:.error, fixIts: [FixItSpec(message:"remove this instance variable."), FixItSpec(message:"convert this instance variable to a static variable.")])
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 5)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				var extra:Int = 0
			}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				var extra:Int = 0
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
			}
			""",
			diagnostics: [expectedDiagnostic],
			macroSpecs:["RAW_staticbuff": MacroSpec(type: RAW_staticbuff_macro.BytesMacro.self, conformances:["RAW_staticbuff", "RAW_accessible", "RAW_decodable", "RAW_encodable", "RAW_comparable"])],
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

	@Test("static variables are allowed")
	func testStaticbuffBytesStaticVar() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 5)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				static let foo = 42
			}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				static let foo = 42

				#RAW_fixed_type(bytes: 5)

				var _bytes: RAW_fixed_type

				public init?(RAW_decode bytes: UnsafeRawBufferPointer) {
				    guard bytes.count == MemoryLayout<RAW_fixed_type>.size else {
				    	return nil
				    }
				    self = bytes.load(as: Self.self)
				}

				public borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ body: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafePointer(to: _bytes) { (ptr: UnsafePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafeMutablePointer(to: &_bytes) { (ptr: UnsafeMutablePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeMutableRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(0, 0, 0, 0, 0)
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
			}
			""",
			macroSpecs:["RAW_staticbuff": MacroSpec(type: RAW_staticbuff_macro.BytesMacro.self, conformances:["RAW_staticbuff", "RAW_accessible", "RAW_decodable", "RAW_encodable", "RAW_comparable"])],
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

	@Test("computed properties are allowed")
	func testStaticbuffBytesComputedVar() throws {
		assertMacroExpansion(
			"""
			@RAW_staticbuff(bytes: 5)
			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				var computed:Int { return 42 }
			}
			""",
			expandedSource:
			"""

			struct MyBuffer:RAW_staticbuff, RAW_decodable {
				var computed:Int { return 42 }

				#RAW_fixed_type(bytes: 5)

				var _bytes: RAW_fixed_type

				public init?(RAW_decode bytes: UnsafeRawBufferPointer) {
				    guard bytes.count == MemoryLayout<RAW_fixed_type>.size else {
				    	return nil
				    }
				    self = bytes.load(as: Self.self)
				}

				public borrowing func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ body: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafePointer(to: _bytes) { (ptr: UnsafePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
				    return try withUnsafeMutablePointer(to: &_bytes) { (ptr: UnsafeMutablePointer<RAW_fixed_type>) throws(E) -> R in
				        return try body(UnsafeMutableRawBufferPointer(start: ptr, count: MemoryLayout<RAW_fixed_type>.size))
				    }
				}

				public init(RAW_staticbuff storetype: consuming RAW_fixed_type) {
					_bytes = storetype
				}

				@available(*, deprecated, message: "use RAW_staticbuff() via RAW_fixed_type conformance instead")
				public consuming func RAW_staticbuff() -> RAW_fixed_type {
					return _bytes
				}

				@available(*, deprecated, message: "use RAW_staticbuff_zeroed() via RAW_fixed_type conformance instead")
				public static func RAW_staticbuff_zeroed() -> RAW_fixed_type {
					(0, 0, 0, 0, 0)
				}

				@available(*, deprecated, message: "use init(RAW_staticbuff storetype:) instead")
				public init(RAW_staticbuff ptr: UnsafeRawPointer) {
					self = ptr.load(as: Self.self)
				}
			}

			extension MyBuffer: RAW_staticbuff, RAW_accessible, RAW_decodable, RAW_encodable, RAW_comparable {
			}
			""",
			macroSpecs:["RAW_staticbuff": MacroSpec(type: RAW_staticbuff_macro.BytesMacro.self, conformances:["RAW_staticbuff", "RAW_accessible", "RAW_decodable", "RAW_encodable", "RAW_comparable"])],
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

