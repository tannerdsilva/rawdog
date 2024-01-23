import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

fileprivate let domain = "RAW_convertible_string_type_macro"
#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:domain)
#endif

internal struct RAW_convertible_string_type_macro:MemberMacro, ExtensionMacro {
	fileprivate class NodeParser:SyntaxVisitor {
		var intType:IdentifierTypeSyntax? = nil
		var unicodeType:DeclReferenceExprSyntax? = nil
		override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
			guard node.count == 1 else {
				return .skipChildren
			}
			return .visitChildren
		}
		override func visit(_ node:LabeledExprListSyntax) -> SyntaxVisitorContinueKind {
			guard node.count == 1 else {
				return .skipChildren
			}
			return .visitChildren
		}
		override func visit(_ node:GenericArgumentSyntax) -> SyntaxVisitorContinueKind {
			let idlister = IdTypeLister(viewMode:.sourceAccurate)
			idlister.walk(node)
			guard idlister.listedIDTypes.count == 1 else {
				return .skipChildren
			}
			if intType == nil {
				intType = idlister.listedIDTypes.first
			}
			return .visitChildren
		}
		override func visit(_ node:DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
			if unicodeType == nil {
				unicodeType = node
			}
			return .skipChildren
		}
	}
    static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        let np = NodeParser(viewMode:.sourceAccurate)
		np.walk(node)
		guard let intType = np.intType, let unicodeType = np.unicodeType else {
			return []
		}
		let structFinder = StructFinder(viewMode:.sourceAccurate)
		structFinder.walk(declaration)
		guard let structDecl = structFinder.structDecl else {
			context.addDiagnostics(from:ExpectedStructAttachment(found:declaration.syntaxNodeType), node:declaration)
			return []
		}

		let bytesVarName = context.makeUniqueName("encoded_bytes_raw")
		let countVarName = context.makeUniqueName("encoded_bytes_count")
		
		var buildDecls = [DeclSyntax]()
		buildDecls.append(DeclSyntax("""
			/// the length of the string without the null terminator
			private var \(countVarName):size_t
		"""))
		buildDecls.append(DeclSyntax("""
			/// this is stored with a terminating byte for C compatibility but this null terminator is not included in the count variable that this instance stores
			private var \(bytesVarName):[UInt8]
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) typealias RAW_convertible_unicode_encoding = \(unicodeType)
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) typealias RAW_integer_encoding_impl = \(intType)
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) func makeIterator() -> RAW_encoded_unicode_iterator<RAW_convertible_unicode_encoding> {
				return \(bytesVarName).withUnsafeBufferPointer({ encBytes in
					return RAW_encoded_unicode_iterator([RAW_convertible_unicode_encoding.CodeUnit](unsafeUninitializedCapacity:(\(countVarName) / MemoryLayout<RAW_convertible_unicode_encoding.CodeUnit>.size), initializingWith: { buff, usedCount in
						usedCount = 0
						var bytes_base = UnsafeRawPointer(encBytes.baseAddress!)
						let bytes_end = bytes_base.advanced(by:\(countVarName))
						while bytes_base < bytes_end {
							var asNative = RAW_integer_encoding_impl.init(RAW_staticbuff_seeking:&bytes_base)
							buff[usedCount] = asNative.RAW_native()
							usedCount += 1
						}
					}).makeIterator(), encoding:RAW_convertible_unicode_encoding.self)
				})
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) init(RAW_decode: UnsafeRawPointer, count: size_t) {
				let asBuffer = UnsafeBufferPointer<UInt8>(start:RAW_decode.assumingMemoryBound(to:UInt8.self), count:count)
				\(bytesVarName) = [UInt8](asBuffer)
				\(countVarName) = count
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) init(_ string:String.UnicodeScalarView) {
				var codeUnitView = string.makeIterator()
				var codeUnit:Unicode.Scalar? = codeUnitView.next()
				
				// a character may produce multiple code units. count the required number of code units first.
				var codeUnits:size_t = 0
				while codeUnit != nil {
					defer {
						codeUnit = codeUnitView.next()
					}
					codeUnits += RAW_convertible_unicode_encoding.width(codeUnit!)
				}

				// reset the iterator
				codeUnitView = string.makeIterator()

				// code units may be larger than one byte
				let encoded_bytes = codeUnits * MemoryLayout<RAW_convertible_unicode_encoding.CodeUnit>.size
				
				\(countVarName) = encoded_bytes
				\(bytesVarName) = [UInt8](unsafeUninitializedCapacity:encoded_bytes, initializingWith: { asBuffer, countout in
					var scalar:Unicode.Scalar? = codeUnitView.next()
					var curHead = asBuffer.baseAddress!
					while scalar != nil {
						defer {
							scalar = codeUnitView.next()
						}
						RAW_convertible_unicode_encoding.encode(scalar!) { codeUnit in
							var nativeCU = RAW_integer_encoding_impl(RAW_native:codeUnit)
							curHead = nativeCU.RAW_encode(dest:curHead)
						}
					}
					countout = asBuffer.baseAddress!.distance(to: curHead)
					#if DEBUG
					assert(countout == encoded_bytes, "countout is not equal to encoded_bytes")
					#endif
				})
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) mutating func RAW_access_mutating<R>(_ body:(inout UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R {
				return try \(bytesVarName).RAW_access_mutating(body)
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) mutating func RAW_encode(count:inout size_t) {
				count += \(countVarName)
			}
		"""))
		buildDecls.append(DeclSyntax("""
			@discardableResult \(structDecl.modifiers) mutating func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
				return \(bytesVarName).RAW_encode(dest:dest)
			}
		"""))
		return buildDecls
    }

    static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		return [
			try ExtensionDeclSyntax("""
				extension \(type):RAW_encoded_unicode {}
			""")
		]
    }
}