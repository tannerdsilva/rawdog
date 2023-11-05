import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

#if RAWDOG_MACRO_LOG
import Logging
let mainLogger = Logger(label:"RAW_macros")
#endif

public struct FixedSizeBufferTypeMacro:MemberMacro, ExtensionMacro, MemberAttributeMacro, AccessorMacro, PeerMacro {
	/// parses the static buffer number from the attribute node.
	fileprivate static func parseNumber(from node:SwiftSyntax.AttributeSyntax) throws -> UInt16 {
		let attributeNumber = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression.as(IntegerLiteralExprSyntax.self)?.literal
		let getNewNumber:UInt16?
		switch attributeNumber {
			case .some(let number):
				guard case .integerLiteral(let value) = number.tokenKind else {
					#if RAWDOG_MACRO_LOG
					mainLogger.critical("expected integer literal")
					#endif
					throw Diagnostics.mustBeIntegerLiteral("\(number)")
				}
				getNewNumber = UInt16(value)
			case .none:
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("expected integer literal")
				#endif
				throw Diagnostics.mustBeIntegerLiteral("\(String(describing: node.arguments))")
		}
		#if RAWDOG_MACRO_LOG
		mainLogger.info("got attribute number", metadata:["attributeNumber": "\(String(describing: getNewNumber!))"])
		#endif
		let newNumber = getNewNumber!
		return newNumber
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
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			logger.critical("expected struct declaration")
			#endif
			throw Diagnostics.mustBeIntegerLiteral("\(declaration)")
		}
		let structureName = structDecl.name
		let structureModifiers = structDecl.modifiers
		let extensionDecl = try ExtensionDeclSyntax("""
			// declares the type as a static buffer type with the given number of bytes as the storetype.
			extension \(structureName):RAW_staticbuff {
				\(structureModifiers) typealias RAW_staticbuff_storetype = \(raw:generateTypeExpression(byteCount:Self.parseNumber(from:node)))
			}
			""")
		let arrayLiteralDecl = try ExtensionDeclSyntax("""
			// declares array literal conformance on the type.
			extension \(structureName):ExpressibleByArrayLiteral {
				/// initializer for array literal expressions of the byte buffer.
				\(structureModifiers) init(arrayLiteral elements: UInt8...) {
					guard elements.count == MemoryLayout<Self.RAW_staticbuff_storetype>.size else {
						fatalError("invalid array literal. the number of elements must match the size of the buffer. expected elements: \\(MemoryLayout<Self.RAW_staticbuff_storetype>.size), found: \\(elements.count)")
					}
					let makeSelf = Self.init(RAW_data:elements)
					if makeSelf != nil {
						self = makeSelf!
					} else {
						fatalError("invalid array literal.")
					}
				}
			}
		""")

		let collectionExtension = try ExtensionDeclSyntax("""
			// declares collection conformance on the type.
			extension \(structureName):Collection {}
		""")
		return [extensionDecl, arrayLiteralDecl, collectionExtension]
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		#if RAWDOG_MACRO_LOG
		var logger = mainLogger
		logger[metadataKey: "mtype"] = "members"
		logger.info("running macro function on node.")
		defer {
			logger.info("macro function finished.")
		}
		#endif
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			logger.critical("expected struct declaration")
			#endif
			throw Diagnostics.mustBeIntegerLiteral("\(declaration)")
		}
		let structureName = structDecl.name
		#if RAWDOG_MACRO_LOG
		logger.info("got structure name.", metadata:["structureName": "\(structureName)"])
		#endif
		let structureModifiers = structDecl.modifiers
		#if RAWDOG_MACRO_LOG
		logger.info("got structure modifiers.", metadata:["structureModifiers": "\(structureModifiers)"])
		#endif
		let attributeNumber = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression.as(IntegerLiteralExprSyntax.self)?.literal
		let getNewNumber:UInt16?
		switch attributeNumber {
			case .some(let number):
				guard case .integerLiteral(let value) = number.tokenKind else {
					#if RAWDOG_MACRO_LOG
					logger.critical("expected integer literal.")
					#endif
					throw Diagnostics.mustBeIntegerLiteral("\(number)")
				}
				getNewNumber = UInt16(value)
				#if RAWDOG_MACRO_LOG
				logger.info("got attribute number.", metadata:["attributeNumber": "\(getNewNumber!)"])
				#endif
			case .none:
				#if RAWDOG_MACRO_LOG
				logger.critical("expected integer literal.")
				#endif
				throw Diagnostics.mustBeIntegerLiteral(String(describing:node.arguments))
		}
		let newNumber = getNewNumber!
		let varSyntax = TokenSyntax.keyword(.let)
		let bufferName = IdentifierPatternSyntax(identifier:TokenSyntax.identifier("fixedBuffer"))
		let typeDecl = generateTypeExpression(byteCount:newNumber)
		let patternBinding = PatternBindingSyntax(pattern:PatternSyntax(bufferName), typeAnnotation:TypeAnnotationSyntax(colon:TokenSyntax.colonToken(), type:typeDecl), initializer:nil, accessorBlock:nil, trailingComma:nil)
		let newList = PatternBindingListSyntax([patternBinding])
		let privateFixedBufferVal = DeclSyntax(VariableDeclSyntax(modifiers:DeclModifierListSyntax([DeclModifierSyntax(name:TokenSyntax.keyword(.private))]), bindingSpecifier:varSyntax, bindings:newList))
		
		// build a tuple initializer that individually references each byte in the input raw pointer.
		var buildPointerRef = "("
		for i in 0..<newNumber {
			buildPointerRef.append("RAW_data!.load(fromByteOffset:\(i), as:UInt8.self)")
			if i + 1 < newNumber {
				buildPointerRef.append(",")
			}
		}
		buildPointerRef.append(")")

		// make the initializer that will allow us to initialize from a raw pointer.
		let initializer = DeclSyntax("""
			/// initializes the type from a raw pointer. it is assumed that the contents of the pointer are of correct size.
			\(structureModifiers) init?(RAW_data:UnsafeRawPointer?) {
				guard RAW_data != nil else {
					return nil
				}
				self.fixedBuffer = \(raw:buildPointerRef)
			}
			""")

		// make the initializer that will allow us to initialize from a raw value type directly.
		let directTypeInit = DeclSyntax("""
			/// initializes the type directly from the raw storage type.
			\(structureModifiers) init(_ val:RAW_staticbuff_storetype) {
				self.fixedBuffer = val
			}
			""")
			
		let asRawFunc = DeclSyntax("""
			/// access the bytes of the static buffer.
			\(structureModifiers) func asRAW_val<R>(_ valFunc: (RAW) throws -> R) rethrows -> R {
				try withUnsafePointer(to:fixedBuffer) { ptr in
					return try valFunc(RAW(RAW_size: MemoryLayout<RAW_staticbuff_storetype>.size, RAW_data: ptr))
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
			\(structureModifiers) subscript(position: Int) -> UInt8 {
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

		return [privateFixedBufferVal, initializer, directTypeInit, asRawFunc, startIndexDecl, endIndexDecl, indexAfterDecl, subscriptDecl]
	}

	public enum Diagnostics:Swift.Error, DiagnosticMessage {
		/// thrown when this macro is attached to a declaration that is not a class
		case mustBeIntegerLiteral(String)
	
		public var severity:DiagnosticSeverity {
			return .error
		}

		public var did:String {
			switch self {
				case .mustBeIntegerLiteral:
					return "RAW_macros.mustBeIntegerLiteral"
			}
		}

		public var message:String {
			switch self {
				case .mustBeIntegerLiteral(let found):
					return "this macro requires an integer literal as its argument. instead found \(found)"
			}
		}

		public var diagnosticID:MessageID {
			return MessageID(domain:"RAW_macros", id:self.did)
		}
	}
}


fileprivate func generateTypeExpression(byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	let byteTypeElement = IdentifierTypeSyntax(name:.identifier("UInt8"))
	var buildContents = TupleTypeElementListSyntax()
	var i:UInt16 = 0
	while i < byteCount {
		var byteTypeElement = TupleTypeElementSyntax(type:byteTypeElement)
		byteTypeElement.trailingComma = i + 1 < byteCount ? TokenSyntax.commaToken() : nil
		buildContents.append(byteTypeElement)
		i += 1
	}
	return TupleTypeSyntax(leftParen:TokenSyntax.leftParenToken(), elements:buildContents, rightParen:TokenSyntax.rightParenToken())
}
