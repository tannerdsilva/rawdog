import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

fileprivate let domain = "RAW_staticbuff_fixedwidthinteger_type_macro"

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:domain)
#endif

internal struct RAW_staticbuff_fixedwidthinteger_type_macro:ExtensionMacro, MemberMacro {
    static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let asStruct = declaration.as(StructDeclSyntax.self) else {
			context.addDiagnostics(from:ExpectedStructAttachment(found:declaration.syntaxNodeType), node:declaration)
			return []
		}
		let nodeSyntax = MacroSyntaxVisitor()
		nodeSyntax.walk(node)
		guard let integerBytes = nodeSyntax.integerBytes else {
			return []
		}
		let memberDecl = DeclSyntax("""
			\(asStruct.modifiers) typealias RAW_staticbuff_storetype = \(generateUnsignedByteTypeExpression(byteCount:UInt16(integerBytes)))
		""")
		let varName = context.makeUniqueName("RAW_staticbuff_private_store")
		let varDecl = DeclSyntax("""
			private var \(varName):RAW_staticbuff_storetype
		""")
		let initDecl = DeclSyntax("""
			/// initialize the static buffer from a pointer to its raw representation store type. behavior is undefined if the raw representation is shorter than the assumed size of the static buffer.
			\(asStruct.modifiers) init(RAW_staticbuff ptr:UnsafeRawPointer) {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "static buffer type stride mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "static buffer type alignment mismatch. this is a misuse of the macro")
				#endif
				self = ptr.load(as:Self.self)
			}
		""")
		return [memberDecl, varDecl, initDecl]
    }

	static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		guard let asStruct = declaration.as(StructDeclSyntax.self) else {
			return []
		}

		let nodeSyntax = MacroSyntaxVisitor()
		nodeSyntax.walk(node)
		guard let integerBytes = nodeSyntax.integerBytes else {
			return []
		}
		guard let isBigEndian = nodeSyntax.isBigEndian else {
			return []
		}
		guard let integerType = nodeSyntax.intergerType else {
			return []
		}
		// collect all the protocols that this macro needs to implement
		var needsConforms = Set<String>()
		for proto in protocols {
			guard let protoId = proto.as(IdentifierTypeSyntax.self) else {
				fatalError()
			}
			let pname = protoId.name.text
			needsConforms.insert(pname)
		}
		let endianFunctionName = isBigEndian ? "bigEndian" : "littleEndian"
		let loadFuncName = integerBytes == 1 ? "load" : "loadUnaligned"
		var buildResults:[ExtensionDeclSyntax] = []
		
		if needsConforms.contains("RAW_comparable_fixed") && needsConforms.contains("RAW_comparable") {
			// no overriding the native comparison operators, as this is a primary goal for this specific macro (to preserve the native sort)
			buildResults.append(try ExtensionDeclSyntax("""
				extension \(type):RAW_comparable_fixed {
					/// compare two instances of the same type.
					\(asStruct.modifiers) static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
						let asLhs = \(raw:integerType.name.text)(\(raw:endianFunctionName):lhs_data.\(raw:loadFuncName)(as:\(raw:integerType.name.text).self))
						let asRhs = \(raw:integerType.name.text)(\(raw:endianFunctionName):rhs_data.\(raw:loadFuncName)(as:\(raw:integerType.name.text).self))
						if asLhs < asRhs {
							return -1
						} else if asLhs > asRhs {
							return 1
						} else {
							return 0
						}
					}
				}
			"""))
			buildResults.append(try ExtensionDeclSyntax("""
				extension \(type):RAW_comparable {
					/// compare two instances of the same type.
					\(asStruct.modifiers) static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:size_t, rhs_data:UnsafeRawPointer, rhs_count:size_t) -> Int32 {
						#if DEBUG
						assert(lhs_count == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
						assert(rhs_count == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
						#endif
						let asLhs = \(raw:integerType.name.text)(\(raw:endianFunctionName):lhs_data.\(raw:loadFuncName)(as:\(raw:integerType.name.text).self))
						let asRhs = \(raw:integerType.name.text)(\(raw:endianFunctionName):rhs_data.\(raw:loadFuncName)(as:\(raw:integerType.name.text).self))
						if asLhs < asRhs {
							return -1
						} else if asLhs > asRhs {
							return 1
						} else {
							return 0
						}
					}
				}
			"""))
		}
		if needsConforms.contains("RAW_staticbuff") {
			buildResults.append(try ExtensionDeclSyntax("""
				extension \(type):RAW_staticbuff {
					
					\(asStruct.modifiers) mutating func RAW_access_staticbuff_mutating<R>(_ body:(UnsafeMutableRawPointer) throws -> R) rethrows -> R {
						return try withUnsafeMutablePointer(to:&self) { buff in
							return try body(buff)
						}
					}
				}
			"""))
		}
		if needsConforms.contains("RAW_accessible") {
			buildResults.append(try ExtensionDeclSyntax("""
				extension \(type):RAW_accessible {
					\(asStruct.modifiers) mutating func RAW_access_mutating<R>(_ body:(inout UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R {
						return try withUnsafeMutablePointer(to:&self) { buff in
							var makeBuffer = UnsafeMutableBufferPointer<UInt8>(start:UnsafeMutableRawPointer(buff).assumingMemoryBound(to:UInt8.self), count:MemoryLayout<RAW_staticbuff_storetype>.size)
							#if DEBUG
							let buffCap = makeBuffer.baseAddress
							defer {
								assert(makeBuffer.baseAddress != buffCap, "you cannot change the underlying buffer of a static buffer type. this is a user error.")
							}
							#endif
							return try body(&makeBuffer)
						}
					}
				}
			"""))
		}

		if needsConforms.contains("RAW_encodable") {
			buildResults.append(try ExtensionDeclSyntax("""
				extension \(type):RAW_encodable {
					/// encodes the type into the given destination pointer.
					/// - returns: a pointer at the end of the the n + 1 memory stride that occurred during the write
					\(asStruct.modifiers) mutating func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
						return withUnsafePointer(to:&self) { valPtr in
							RAW_memcpy(dest, valPtr, MemoryLayout<RAW_staticbuff_storetype>.size)
						}!.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
					}

					/// encodes the byte count of the encoding to the given ``size_t`` pointer.
					\(asStruct.modifiers) mutating func RAW_encode(count:inout size_t) {
						count += MemoryLayout<RAW_staticbuff_storetype>.size
					}
				}
			"""))
		}

		if needsConforms.contains("RAW_decodable") {
			buildResults.append(try ExtensionDeclSyntax("""
				extension \(type):RAW_decodable {
					/// initialize from the contents of a raw data buffer.
					/// the byte buffer SHOULD be considered comprehensive and exact, meaning that any failure to stride in full should result in a nil return.
					/// - note: the initializer may returrn nil if the value is considered invalid or malformed.
					\(asStruct.modifiers) init?(RAW_decode ptr:UnsafeRawPointer, count:size_t) {
						#if DEBUG
						assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
						assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "static buffer type stride mismatch. this is a misuse of the macro")
						assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "static buffer type alignment mismatch. this is a misuse of the macro")
						#endif

						guard count == MemoryLayout<RAW_staticbuff_storetype>.size else {
							return nil
						}
						self = ptr.load(as:Self.self)
					}
				}
			"""))
		}

		if needsConforms.contains("RAW_fixed") {
			buildResults.append(try ExtensionDeclSyntax("""
				extension \(type):RAW_fixed {
					/// the fixed byte count of the type.
					\(asStruct.modifiers) typealias RAW_fixed_type = \(generateUnsignedByteTypeExpression(byteCount:UInt16(integerBytes)))
				}
			"""))
		}

		if needsConforms.contains("RAW_convertible_fixed") {
			buildResults.append(try ExtensionDeclSyntax("""
				extension \(type):RAW_convertible_fixed {
					/// initialize from the contents of a raw data buffer.
					/// the byte buffer SHOULD be considered comprehensive and exact, meaning that any failure to stride in full should result in a nil return.
					/// - note: the initializer may returrn nil if the value is considered invalid or malformed.
					\(asStruct.modifiers) init?(RAW_decode ptr:UnsafeRawPointer) {
						#if DEBUG
						assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
						assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "static buffer type stride mismatch. this is a misuse of the macro")
						assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "static buffer type alignment mismatch. this is a misuse of the macro")
						#endif
						self = ptr.load(as:Self.self)
					}
				}
			"""))
		}

		if needsConforms.contains("RAW_native") {
			buildResults.append(try ExtensionDeclSyntax("""
				extension \(type):RAW_native {
					/// the raw data that the structure instance represents.
					\(asStruct.modifiers) init(RAW_native val:\(raw:integerType.name.text))) {
						self.init(RAW_staticbuff:[val.\(raw:endianFunctionName)])
					}
					\(asStruct.modifiers) mutating func RAW_native() -> \(raw:integerType.name.text) {
						return withUnsafePointer(to:&self) { ptr in
							return \(raw:integerType.name.text)(\(raw:endianFunctionName):UnsafeRawPointer(ptr).load(as:\(raw:integerType.name.text).self))
						}
					}
				}
			"""))
		}

		if needsConforms.contains("RAW_encoded_fixedwidthinteger") {
			buildResults.append(try ExtensionDeclSyntax("""
				extension \(type):RAW_encoded_fixedwidthinteger {}
			"""))
		}

		if needsConforms.contains("ExpressibleByIntegerLiteral") {
			buildResults.append(try ExtensionDeclSyntax("""
				extension \(type):ExpressibleByIntegerLiteral {
					\(asStruct.modifiers) init(integerLiteral value:\(raw:integerType.name.text)) {
						self = withUnsafePointer(to:value.bigEndian) { ptr in
							Self(RAW_staticbuff:ptr)
						}
					}
				}
			"""))
		}
		

		return buildResults
	}

	// the primary tool that parses the macro node and determines how it should expand based on user configuration input.
	internal class MacroSyntaxVisitor:SingleTypeGenericArgumentFinder {
		
		internal var integerBytes:Int? = nil
		internal var isBigEndian:Bool? = nil
		internal var intergerType:IdentifierTypeSyntax? = nil

		internal init() {
			super.init(viewMode:.sourceAccurate)
		}

		override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
			let idParser = IdTypeLister(viewMode:.sourceAccurate)
			idParser.walk(node)
			guard idParser.listedIDTypes.count == 1 else {
				#if RAWDOG_MACRO_LOG
				mainLogger.error("expected exactly one generic argument, but got \(idParser.listedIDTypes.count)")
				#endif
				return .skipChildren
			}
			intergerType = idParser.listedIDTypes.first
			return .skipChildren
		}

		override func visit(_ node:LabeledExprSyntax) -> SyntaxVisitorContinueKind {
			switch node.label?.text {
				case "bits":
					guard let intLiteral = node.expression.as(IntegerLiteralExprSyntax.self) else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected an IntegerLiteralExprSyntax for the bits argument, but got \(node.expression)")
						#endif
						return .skipChildren
					}
					guard let bits = Int(intLiteral.literal.text) else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected an integer literal for the bits argument, but got \(intLiteral.literal)")
						#endif
						return .skipChildren
					}
					guard bits % 8 == 0 else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected a multiple of 8 for the bits argument, but got \(bits)")
						#endif
						return .skipChildren
					}
					integerBytes = bits / 8
					return .visitChildren
				case "bigEndian":
					guard let boolLiteral = node.expression.as(BooleanLiteralExprSyntax.self) else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected a BooleanLiteralExprSyntax for the bigEndian argument, but got \(node.expression)")
						#endif
						return .skipChildren
					}
					isBigEndian = (boolLiteral.literal.text == "true")
					return .visitChildren
				default:
					#if RAWDOG_MACRO_LOG
					mainLogger.error("unexpected label \(node.label?.text ?? "<nil>")")
					#endif
					return .skipChildren
			}
		}
	}

	// // primary interpretation tool for the attached syntax.
	// internal class AttachedSyntaxVisitor:SyntaxVisitor {
	// 	internal let context:MacroExpansionContext
	// 	internal var inheritedTypes:Set<IdentifierTypeSyntax> = []

	// 	init(context:MacroExpansionContext) {
	// 		self.context = context
	// 		super.init(viewMode:.sourceAccurate)
	// 	}

	// 	override func visit(_ node:InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
	// 		#if RAWDOG_MACRO_LOG
	// 		mainLogger.notice("found inherited type list \(node). parsing will continue.")
	// 		#endif
	// 		let idScanner = IdTypeLister(viewMode:.sourceAccurate)
	// 		idScanner.walk(node)
	// 		inheritedTypes = idScanner.listedIDTypes
	// 		return .skipChildren
	// 	}

	// 	override func visit(_ node:FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
	// 		#if RAWDOG_MACRO_LOG
	// 		mainLogger.notice("found function declaration \(node). parsing will continue.")
	// 		#endif
	// 		context.addDiagnostics(from:Diagnostics.functionDeclarationsUnsupported, node:node)
	// 		return .skipChildren
	// 	}

	// 	override func visit(_ node:VariableDeclSyntax) -> SyntaxVisitorContinueKind {
	// 		#if RAWDOG_MACRO_LOG
	// 		mainLogger.notice("found variable declaration \(node). parsing will continue.")
	// 		#endif
	// 		context.addDiagnostics(from:Diagnostics.variableDeclarationsNotSupported, node:node)
	// 		return .skipChildren
	// 	}
	// }
	
	// internal struct UsageConfiguration {
	// 	internal let structName:String
	// 	internal let integerType:String
	// 	internal let integerBytes:Int
	// 	internal let isBigEndian:Bool
	// 	internal var endianFunctionName:String {
	// 		return isBigEndian ? "bigEndian" : "littleEndian"
	// 	}
	// 	internal var inheritedTypes:Set<IdentifierTypeSyntax> = []
	// 	internal var modifierList:DeclModifierListSyntax = []
	// }

	// /// parses the available syntax to determine how this macro should expand (based on user configuration).
	// internal static func parseUsageConfig(node:SwiftSyntax.AttributeSyntax, attachedTo declaration:some SyntaxProtocol, context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> UsageConfiguration {
	// 	guard let structDecl = declaration.as(StructDeclSyntax.self) else {
	// 		context.addDiagnostics(from:Diagnostics.expectedStructDeclaration(declaration.syntaxNodeType), node:declaration)
	// 		throw Diagnostics.expectedStructDeclaration(declaration.syntaxNodeType)
	// 	}
	// 	let attachedStructName = structDecl.name.text
	// 	let modifiers = structDecl.modifiers
	// 	let parser = MacroSyntaxVisitor()
	// 	parser.walk(node)
	// 	let bytes = parser.integerBytes!
	// 	let isBigEndian = parser.isBigEndian!
	// 	let attachedParser = AttachedSyntaxVisitor(context:context)
	// 	attachedParser.walk(declaration)
	// 	return UsageConfiguration(structName:attachedStructName, integerType:parser.foundType!.name.text, integerBytes:bytes, isBigEndian:isBigEndian, inheritedTypes:attachedParser.inheritedTypes, modifierList:modifiers)
	// }

	// public enum Diagnostics:Swift.Error, DiagnosticMessage {
	//     public var message:String {
	// 		switch self {
	// 			case .expectedStructDeclaration(let node):
	// 				return "``@RAW_staticbuff_fixedwidthinteger_type`` expects to be attached to a struct declaration. instead, found attachment to \(node)"
	// 			case .functionDeclarationsUnsupported:
	// 				return "direct function declarations are not supported in the syntax that ``@RAW_staticbuff_fixedwidthinteger_type`` attaches to. please move this function into a standalone extension."
	// 			case .variableDeclarationsNotSupported:
	// 				return "direct variable declarations are not supported in the syntax that ``@RAW_staticbuff_fixedwidthinteger_type`` attaches to. please implement this variable as a computed property in a standalone extension."
	// 		}
	// 	}

	//     public var diagnosticID: SwiftDiagnostics.MessageID {
	// 		switch self {
	// 			case .expectedStructDeclaration(_):
	// 				return MessageID(domain:domain, id:"expectedStructDeclaration")
	// 			case .functionDeclarationsUnsupported:
	// 				return MessageID(domain:domain, id:"functionDeclarationsUnsupported")
	// 			case .variableDeclarationsNotSupported:
	// 				return MessageID(domain:domain, id:"variableDeclarationsNotSupported")
	// 		}
	// 	}

	// 	case expectedStructDeclaration(SyntaxProtocol.Type)
	// 	case functionDeclarationsUnsupported
	// 	case variableDeclarationsNotSupported

	// 	public var severity:DiagnosticSeverity {
	// 		return .error
	// 	}
	// }
}
