import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:"RAW_val_fixed")
#endif

public struct FixedSizeBufferTypeMacro:MemberMacro, ExtensionMacro, MemberAttributeMacro, AccessorMacro, PeerMacro {
	/// parses the static buffer number from the attribute node.
	fileprivate static func parseNumber(from node:SwiftSyntax.AttributeSyntax) throws -> (bytes:UInt16, type:IdentifierTypeSyntax) {
		let labeledExpressionList = node.arguments!.as(LabeledExprListSyntax.self)!
		var getNewNumber:UInt16? = nil
		var getUnsigned:Bool? = nil
		for (i, curItem) in labeledExpressionList.enumerated() {
			switch i {
				case 0:
					// get the number of bytes
					let number = curItem.expression.as(IntegerLiteralExprSyntax.self)!.literal
					guard case .integerLiteral(let value) = number.tokenKind else {
						#if RAWDOG_MACRO_LOG
						mainLogger.critical("expected integer literal")
						#endif
						throw Diagnostics.mustBeIntegerLiteral("\(number)")
					}
					getNewNumber = UInt16(value)
					#if RAWDOG_MACRO_LOG
					mainLogger.info("got attribute number", metadata:["attributeNumber": "\(getNewNumber!)"])
					#endif
				case 1:
					// get the unsigned flag
					let bool = curItem.expression.as(BooleanLiteralExprSyntax.self)!.literal
					switch bool.tokenKind {
						case TokenKind.keyword(.true):
							getUnsigned = true
						case TokenKind.keyword(.false):
							getUnsigned = false
						default:
							#if RAWDOG_MACRO_LOG
							mainLogger.critical("expected boolean literal")
							#endif
							throw Diagnostics.mustBeBooleanLiteral("\(bool)")
					}
					#if RAWDOG_MACRO_LOG
					mainLogger.info("got attribute unsigned flag", metadata:["attributeUnsigned": "\(getUnsigned!)"])
					#endif
				default:
					#if RAWDOG_MACRO_LOG
					mainLogger.critical("expected 2 arguments")
					#endif
					throw Diagnostics.mustBeIntegerLiteral("\(String(describing: node.arguments))")
			}
		}
		let type = getUnsigned! ? IdentifierTypeSyntax(name:.identifier("UInt8")) : IdentifierTypeSyntax(name:.identifier("Int8"))
		return (getNewNumber!, type)
	}

	fileprivate static func parseAttachedDeclGroupSyntax(_ declaration:some DeclGroupSyntax) throws -> (structureName:TokenSyntax, structureModifiers:DeclModifierListSyntax) {
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.critical("expected struct declaration. found \(declaration)")
			#endif
			throw Diagnostics.mustBeStructOrClassDeclaration(declaration.syntaxNodeType)
		}
		let structureName = structDecl.name
		#if RAWDOG_MACRO_LOG
		mainLogger.info("got structure name", metadata:["structureName": "\(structureName)"])
		#endif
		let structureModifiers = structDecl.modifiers
		#if RAWDOG_MACRO_LOG
		mainLogger.info("got structure modifiers", metadata:["structureModifiers": "\(structureModifiers)"])
		#endif
		return (structureName, structureModifiers)
	}
	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AttributeSyntax] {
		return []
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AccessorDeclSyntax] {
		return []
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		return []
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		#if RAWDOG_MACRO_LOG
		var logger = mainLogger
		logger[metadataKey: "mtype"] = "extension"
		logger.info("running macro function on node '\(declaration.description).")
		defer {
			logger.info("macro function finished.")
		}
		#endif
		let (structureName, structureModifiers) = try Self.parseAttachedDeclGroupSyntax(declaration)
		let (newNumber, byteType) = try Self.parseNumber(from:node)
		var buildEqualities = [String]()
		for i in 0..<newNumber {
			buildEqualities.append("lhs.fixedBuffer.\(i) == rhs.fixedBuffer.\(i)")
		}

		var returnResult = [SwiftSyntax.ExtensionDeclSyntax]()

		let rawComparableConformance = try ExtensionDeclSyntax("""
			extension \(structureName):RAW_comparable {
				/// default implementation that compares the raw representation of the type.
				\(structureModifiers) static func RAW_compare(_ lhs:val, _ rhs:val) -> Int32 {
					return memcmp(lhs.RAW_data, rhs.RAW_data, lhs.RAW_size)
				}
			}
		""")
		returnResult.append(rawComparableConformance)

		let comparableConformance = try ExtensionDeclSyntax("""
			// declares comparable conformance on the type.
			extension \(structureName):Comparable {
				/// default implementation that compares the raw representation of the type.
				\(structureModifiers) static func < (lhs:Self, rhs:Self) -> Bool {
					withUnsafePointer(to:lhs.fixedBuffer) { lhsPtr in
						withUnsafePointer(to:rhs.fixedBuffer) { rhsPtr in
							return memcmp(lhsPtr, rhsPtr, MemoryLayout<RAW_staticbuff_storetype>.size) < 0
						}
					}
				}
			}
		""")
		returnResult.append(comparableConformance)
		
		// extend the structure to conform to equatable if it does not already.
		let equatableConformance = try ExtensionDeclSyntax("""
			// declares equatable conformance on the type.
			extension \(structureName):Equatable {
				/// default implementation that compares the raw representation of the type.
				\(structureModifiers) static func == (lhs:Self, rhs:Self) -> Bool {
					return ( \(raw:buildEqualities.joined(separator:" && ")) )
				}
			}
		""")
		returnResult.append(equatableConformance)

		returnResult.append(try ExtensionDeclSyntax("""
			// declares the type as a static buffer type with the given number of bytes as the storetype.
			extension \(structureName):RAW_staticbuff {
				\(structureModifiers) typealias RAW_staticbuff_storetype = \(raw:generateTypeExpression(typeSyntax:byteType, byteCount:newNumber))
			}
		"""))
		returnResult.append(try ExtensionDeclSyntax("""
			// declares array literal conformance on the type.
			extension \(structureName):ExpressibleByArrayLiteral {
				/// initializer for array literal expressions of the byte buffer.
				\(structureModifiers) init(arrayLiteral elements: \(byteType)...) {
					guard elements.count == MemoryLayout<Self.RAW_staticbuff_storetype>.size else {
						fatalError("invalid array literal. the number of elements must match the size of the buffer. expected elements: \\(MemoryLayout<Self.RAW_staticbuff_storetype>.size), found: \\(elements.count)")
					}
					self = Self.init(RAW_data:elements)
				}
			}
		"""))

		returnResult.append(try ExtensionDeclSyntax("""
			// declares collection conformance on the type.
			extension \(structureName):Collection {}
		"""))
		return returnResult
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		#if RAWDOG_MACRO_LOG
		var logger = mainLogger
		logger[metadataKey: "mtype"] = "members"
		logger.debug("running fixed-length value macro.")
		defer {
			logger.debug("done running fixed-length value macro.")
		}
		#endif
		let (structureName, structureModifiers) = try Self.parseAttachedDeclGroupSyntax(declaration)
		#if RAWDOG_MACRO_LOG
		logger.trace("got structure name.", metadata:["name": "\(structureName)"])
		logger.trace("got structure modifiers.", metadata:["mods": "\(structureModifiers)"])
		#endif
		let (newNumber, byteType) = try Self.parseNumber(from:node)
		let varSyntax = TokenSyntax.keyword(.let)
		let bufferName = IdentifierPatternSyntax(identifier:TokenSyntax.identifier("fixedBuffer"))
		let typeDecl:TupleTypeSyntax = generateTypeExpression(typeSyntax:byteType, byteCount:newNumber)
		let patternBinding = PatternBindingSyntax(pattern:PatternSyntax(bufferName), typeAnnotation:TypeAnnotationSyntax(colon:TokenSyntax.colonToken(), type:typeDecl), initializer:nil, accessorBlock:nil, trailingComma:nil)
		let newList = PatternBindingListSyntax([patternBinding])
		let privateFixedBufferVal = DeclSyntax(VariableDeclSyntax(modifiers:DeclModifierListSyntax([DeclModifierSyntax(name:TokenSyntax.keyword(.internal))]), bindingSpecifier:varSyntax, bindings:newList))
		
		// build a tuple initializer that individually references each byte in the input raw pointer.
		var buildPointerRef = "("
		for i in 0..<newNumber {
			buildPointerRef.append("RAW_data.load(fromByteOffset:\(i), as:\(byteType).self)")
			if i + 1 < newNumber {
				buildPointerRef.append(",")
			}
		}
		buildPointerRef.append(")")

		// make the initializer that will allow us to initialize from a raw pointer.
		let initializer = DeclSyntax("""
			/// initializes the type from a raw pointer. it is assumed that the contents of the pointer are of correct size.
			\(structureModifiers) init(RAW_data:UnsafeRawPointer) {
				self.fixedBuffer = RAW_data.load(as:\(typeDecl).self)
			}
			""")

		// make the initializer that will allow us to initialize from a raw value type directly.
		let directTypeInit = DeclSyntax("""
			/// initializes the type directly from the raw storage type.
			\(structureModifiers) init(RAW_staticbuff_storetype val:RAW_staticbuff_storetype) {
				self.fixedBuffer = val
			}
			""")
			
		let rawCountAdd = DeclSyntax("""
			/// adds the size of the raw memory representation to the given pointer.
			\(structureModifiers) func addRAW_val_size(into size:inout size_t) {
				size += \(raw:newNumber)
			}
			""")

		let rawCopy = DeclSyntax("""
			/// copies the raw memory representation into the given buffer.
			\(structureModifiers) func copyRAW_val(into buffer: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
				return withUnsafePointer(to:fixedBuffer) { ptr in
					return RAW_memcpy(buffer, ptr, MemoryLayout<RAW_staticbuff_storetype>.size)!
				}
			}
			""")

		let asRawFunc = DeclSyntax("""
			/// access the bytes of the static buffer.
			\(structureModifiers) func asRAW_val<R>(_ valFunc:(UnsafeRawPointer, UnsafePointer<size_t>) throws -> R) rethrows -> R {
				try withUnsafePointer(to:fixedBuffer) { ptr in
					return try withUnsafePointer(to:MemoryLayout<RAW_staticbuff_storetype>.size) { sizePtr in
						return try valFunc(ptr, sizePtr)
					}
				}
			}
			""")

		// collection stuff
		let startIndexDecl = DeclSyntax("""
			/// (collection conformance) the starting index of the byte collection.
			\(structureModifiers) var startIndex: Int {
				return 0
			}
			""")

		let endIndexDecl = DeclSyntax("""
			/// (collection conformance) the ending index of the byte collection.
			\(structureModifiers) var endIndex: Int {
				return MemoryLayout<RAW_staticbuff_storetype>.size
			}
			""")
		
		var forContents = ""
		for i in 0..<newNumber {
			forContents.append("case \(i): return fixedBuffer.\(i)")
			if i + 1 < newNumber {
				forContents.append("\n")
			}
		}
		let subscriptDecl = DeclSyntax("""
			/// (collection conformance) access any given byte in the collection by index.
			\(structureModifiers) subscript(position: Int) -> \(byteType) {
				switch position {
					\(raw:forContents)
					default: fatalError("invalid index.")
				}
			}
			""")
		
		let indexAfterDecl = DeclSyntax("""
			/// (collection conformance) returns the index after the given index.
			\(structureModifiers) func index(after i: Int) -> Int {
				return i + 1
			}
			""")

		

		return [rawCopy, rawCountAdd, privateFixedBufferVal, initializer, directTypeInit, asRawFunc, startIndexDecl, endIndexDecl, indexAfterDecl, subscriptDecl]
	}

	public enum Diagnostics:Swift.Error, DiagnosticMessage {
		/// thrown when this macro is attached to a declaration that is not a class
		case mustBeIntegerLiteral(String)

		/// thrown when this macro is attached to a declaration that is not a structure or class
		case mustBeBooleanLiteral(String)

		/// thrown when this macro is attached to a declaration that is not a structure or class
		case mustBeStructOrClassDeclaration(SyntaxProtocol.Type)
	
		public var severity:DiagnosticSeverity {
			return .error
		}

		public var did:String {
			switch self {
				case .mustBeIntegerLiteral:
					return "RAW_val_fixed.mustBeIntegerLiteral"
				case .mustBeStructOrClassDeclaration:
					return "RAW_val_fixed.mustBeStructOrClassDeclaration"
			case .mustBeBooleanLiteral(_):
				return "RAW_val_fixed.mustBeBooleanLiteral"
}
		}

		public var message:String {
			switch self {
				case .mustBeIntegerLiteral(let found):
					return "this macro requires an integer literal as its argument. instead found \(found)"
				case .mustBeStructOrClassDeclaration(let declType):
					return "this macro must be attached to a struct or class declaration. instead found \(declType)"
				case .mustBeBooleanLiteral(let found):
					return "this macro requires a boolean literal as its argument. instead found \(found)"
			}
		}

		public var diagnosticID:MessageID {
			return MessageID(domain:"RAW_macros", id:self.did)
		}
	}
}

fileprivate func generateSignedByteTypeExpression(byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	return generateTypeExpression(typeSyntax:IdentifierTypeSyntax(name:.identifier("Int8")), byteCount:byteCount)
}
fileprivate func generateUnsignedByteTypeExpression(byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	return generateTypeExpression(typeSyntax:IdentifierTypeSyntax(name:.identifier("UInt8")), byteCount:byteCount)
}
fileprivate func generateTypeExpression(typeSyntax:IdentifierTypeSyntax, byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	var buildContents = TupleTypeElementListSyntax()
	var i:UInt16 = 0
	while i < byteCount {
		var byteTypeElement = TupleTypeElementSyntax(type:typeSyntax)
		byteTypeElement.trailingComma = i + 1 < byteCount ? TokenSyntax.commaToken() : nil
		buildContents.append(byteTypeElement)
		i += 1
	}
	return TupleTypeSyntax(leftParen:TokenSyntax.leftParenToken(), elements:buildContents, rightParen:TokenSyntax.rightParenToken())
}
