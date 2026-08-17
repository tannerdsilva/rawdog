// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

/// attached member + extension macro that generates the implementation of `RAW_encoded_unicode` for a struct.
///
/// usage:
/// ```swift
/// @RAW_convertible_string_type<UTF8>(backing: UInt32BigEndian.self)
/// struct MyString {}
/// ```
internal struct RAW_convertible_string_type_macro:MemberMacro, ExtensionMacro {

	// MARK: - argument extraction

	fileprivate struct ParsedArgs {
		let unicodeType:String
		let backingType:String
	}

	fileprivate static func extractArgs(from node:AttributeSyntax) -> ParsedArgs? {
		guard let args = node.arguments?.as(LabeledExprListSyntax.self) else {
			return nil
		}

		// extract the generic argument (UnicodeCodec type)
		guard let genericClause = node.attributeName.as(IdentifierTypeSyntax.self)?.genericArgumentClause,
			  let unicodeType = genericClause.arguments.first?.argument.as(IdentifierTypeSyntax.self)?.name.text else {
			return nil
		}

		// extract the backing type from the `backing:` argument
		guard let backingArg = args.first(where: { $0.label?.text == "backing" }),
			  let backingExpr = backingArg.expression.as(MemberAccessExprSyntax.self),
			  let backingType = backingExpr.base?.trimmedDescription else {
			return nil
		}

		return ParsedArgs(unicodeType: unicodeType, backingType: backingType)
	}

	// MARK: - ExtensionMacro

	static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax, providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
		return [
			try! ExtensionDeclSyntax("extension \(type):RAW_encoded_unicode {}")
		]
	}

	// MARK: - MemberMacro

	static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
		guard let args = extractArgs(from: node) else {
			return []
		}

		let countVarName = context.makeUniqueName("encoded_bytes_count")
		let bytesVarName = context.makeUniqueName("encoded_bytes_raw")

		var result = [DeclSyntax]()

		// stored properties
		result.append(DeclSyntax("""
		/// the length of the string without the null terminator
		private let \(countVarName):size_t
		"""))
		result.append(DeclSyntax("""
		/// this is stored with a terminating byte for C compatibility but this null terminator is not included in the count variable that this instance stores
		private var \(bytesVarName):[UInt8]
		"""))

		// typealiases
		result.append(DeclSyntax("""
		public typealias RAW_convertible_unicode_encoding = \(raw: args.unicodeType)
		"""))
		result.append(DeclSyntax("""
		public typealias RAW_integer_encoding_impl = \(raw: args.backingType)
		"""))

		// makeIterator
		result.append(DeclSyntax("""
		public consuming func makeIterator() -> RAW_encoded_unicode_iterator<Self> {
			return RAW_encoded_unicode_iterator(\(bytesVarName), encoding:Self.self)
		}
		"""))

		// init(RAW_decode:)
		result.append(DeclSyntax("""
		public init?(RAW_decode buffer:UnsafeRawBufferPointer) {
			let asBuffer = UnsafeBufferPointer<UInt8>(start:buffer.baseAddress?.assumingMemoryBound(to:UInt8.self), count:buffer.count)
			\(bytesVarName) = [UInt8](asBuffer)
			\(countVarName) = buffer.count
		}
		"""))

		// init(_: String.UnicodeScalarView)
		result.append(DeclSyntax("""
		public init(_ string:consuming String.UnicodeScalarView) {
			var byteCount:size_t = 0
			var bytes:[UInt8] = []
			for curScalar in string {
				RAW_convertible_unicode_encoding.encode(curScalar) { codeUnit in
					withUnsafePointer(to: codeUnit) { ptr in
						let rawPtr = UnsafeRawPointer(ptr)
						let count = MemoryLayout<RAW_convertible_unicode_encoding.CodeUnit>.size
						bytes.append(contentsOf: UnsafeBufferPointer<UInt8>(start: rawPtr.assumingMemoryBound(to: UInt8.self), count: count))
						byteCount += count
					}
				}
			}
			\(countVarName) = byteCount
			\(bytesVarName) = bytes
		}
		"""))

		// RAW_access_immutable
		result.append(DeclSyntax("""
		public borrowing func RAW_access_immutable<R, E>(_ body:(UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
			return try \(bytesVarName).withUnsafeBytes { buffer in
				try body(buffer)
			}
		}
		"""))

		// RAW_access_mutable
		result.append(DeclSyntax("""
		public mutating func RAW_access_mutable<R, E>(_ body:(UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
			return try \(bytesVarName).withUnsafeMutableBytes { buffer in
				try body(buffer)
			}
		}
		"""))

		// RAW_encode(count:)
		result.append(DeclSyntax("""
		public borrowing func RAW_encode(count:inout Int) {
			count += \(countVarName)
		}
		"""))

		// RAW_encode(_:destination:)
		result.append(DeclSyntax("""
		@discardableResult public borrowing func RAW_encode(_:UnsafeMutableRawPointer.Type, destination:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
			return \(bytesVarName).withUnsafeBytes { buffer in
				let dest = destination
				dest.copyMemory(from: buffer.baseAddress!, byteCount: buffer.count)
				return dest.advanced(by: buffer.count)
			}
		}
		"""))

		return result
	}
}
