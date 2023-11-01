import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Logging

let mainLogger = Logger(label:"RAW_macros")

public struct FixedSizeBufferTypeMacro:MemberMacro, ExtensionMacro, MemberAttributeMacro, AccessorMacro, PeerMacro {
	/// parses the static buffer number from the attribute node.
	fileprivate static func parseNumber(from node:SwiftSyntax.AttributeSyntax) throws -> UInt16 {
		let attributeNumber = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression.as(IntegerLiteralExprSyntax.self)?.literal
		let getNewNumber:UInt16?
		switch attributeNumber {
			case .some(let number):
				guard case .integerLiteral(let value) = number.tokenKind else {
					mainLogger.critical("expected integer literal")
					throw Diagnostics.mustBeIntegerLiteral("\(number)")
				}
				getNewNumber = UInt16(value)
			case .none:
				mainLogger.critical("expected integer literal")
				throw Diagnostics.mustBeIntegerLiteral("\(String(describing: node.arguments))")
		}
		mainLogger.info("got attribute number", metadata:["attributeNumber": "\(String(describing: getNewNumber!))"])
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
		var logger = mainLogger
		logger[metadataKey: "mtype"] = "extension"
		logger.info("running macro function on node '\(declaration.description).")
		defer {
			logger.info("macro function finished.")
		}
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			mainLogger.critical("expected struct declaration")
			throw Diagnostics.mustBeIntegerLiteral("\(declaration)")
		}
		let structureName = structDecl.name		
		let extensionDecl = try ExtensionDeclSyntax("""
			extension \(structureName):RAW_staticbuff {
				typealias RAW_staticbuff_storetype = \(raw:generateTypeExpression(byteCount:Self.parseNumber(from:node)))
			}
			""")
		let arrayLiteralDecl = try ExtensionDeclSyntax("""
			extension \(structureName):ExpressibleByArrayLiteral {
				init(arrayLiteral elements: UInt8...) {
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
			extension \(structureName):Collection {}
		""")
		return [extensionDecl, arrayLiteralDecl, collectionExtension]
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		var logger = mainLogger
		logger[metadataKey: "mtype"] = "members"
		logger.info("running macro function on node.")
		defer {
			logger.info("macro function finished.")
		}
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			logger.critical("expected struct declaration")
			throw Diagnostics.mustBeIntegerLiteral("\(declaration)")
		}
		let structureName = structDecl.name
		logger.info("got structure name.", metadata:["structureName": "\(structureName)"])
		let structureModifiers = structDecl.modifiers
		logger.info("got structure modifiers.", metadata:["structureModifiers": "\(structureModifiers)"])
		let attributeNumber = node.arguments?.as(LabeledExprListSyntax.self)?.first?.expression.as(IntegerLiteralExprSyntax.self)?.literal
		let getNewNumber:UInt16?
		switch attributeNumber {
			case .some(let number):
				guard case .integerLiteral(let value) = number.tokenKind else {
					logger.critical("expected integer literal.")
					throw Diagnostics.mustBeIntegerLiteral("\(number)")
				}
				getNewNumber = UInt16(value)
				logger.info("got attribute number.", metadata:["attributeNumber": "\(getNewNumber!)"])
			case .none:
				logger.critical("expected integer literal.")
				throw Diagnostics.mustBeIntegerLiteral("\(node.arguments)")
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
			\(structureModifiers) init?(RAW_data:UnsafeRawPointer?) {
				guard RAW_data != nil else {
					fatalError("invalid pointer.")
				}
				self.fixedBuffer = \(raw:buildPointerRef)
			}
			""")

		// make the initializer that will allow us to initialize from a raw value type directly.
		let directTypeInit = DeclSyntax("""
			\(structureModifiers) init(_ val:RAW_staticbuff_storetype) {
				self.fixedBuffer = val
			}
			""")
			
		let asRawFunc = DeclSyntax("""
			\(structureModifiers) func asRAW_val<R>(_ valFunc: (RAW) throws -> R) rethrows -> R {
				try withUnsafePointer(to:fixedBuffer) { ptr in
					return try valFunc(RAW(RAW_size: MemoryLayout<RAW_staticbuff_storetype>.size, RAW_data: ptr))
				}
			}
			""")

		// collection stuff
		let startIndexDecl = DeclSyntax("""
			\(structureModifiers) var startIndex: Int {
				return 0
			}
			""")

		let endIndexDecl = DeclSyntax("""
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
			\(structureModifiers) subscript(position: Int) -> UInt8 {
				switch position {
					\(raw:forContents)
					default: fatalError("invalid index.")
				}
			}
			""")
		
		let indexAfterDecl = DeclSyntax("""
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
