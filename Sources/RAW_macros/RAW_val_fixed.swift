import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Logging

let mainLogger = Logger(label:"RAW_macros")

public struct FixedSizeBufferTypeMacro:DeclarationMacro {
	public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		mainLogger.critical("node \(node)")
		mainLogger.critical("context \(context)")
		return []
	}

	private class VariableDeclRewriter:SyntaxRewriter {
		private let log:Logger?
		private static let disableSelfMacroExpression = false
		private let tt:TupleTypeSyntax
		fileprivate init(tupleType:TupleTypeSyntax, log:Logger?) {
			self.log = log
			self.tt = tupleType
		}

		override func visit(_ node:PatternBindingSyntax) -> PatternBindingSyntax {
			var getNode = node
			getNode.typeAnnotation = TypeAnnotationSyntax(colon:TokenSyntax.colonToken(), type:self.tt)
			return getNode
		}

		override func visit(_ node:AttributeListSyntax) -> AttributeListSyntax {
			if Self.disableSelfMacroExpression {
				return node
			}
			var logger = log
			logger?[metadataKey: "ntype"] = "attribute"
			logger?.info("rewriting node.")
			defer {
				logger?.info("done rewriting node.")
			}
			var newAttributes = AttributeListSyntax()
			for attributeEl in node {
				if let attribute = attributeEl.as(AttributeSyntax.self), let identifierSyntax = attribute.attributeName.as(IdentifierTypeSyntax.self) {
					if identifierSyntax.name.text != "FixedSizeBufferMacro" {
						newAttributes.append(attributeEl) 
					} else {
						mainLogger.trace("found FixedSizeBufferMacro attribute. it will be removed from the syntax.")
						continue
					}
				} else {
					newAttributes.append(attributeEl)
				}
			}
			return newAttributes
		}
	}
}

public struct FixedBuffer:MemberMacro, ExtensionMacro, MemberAttributeMacro, AccessorMacro, PeerMacro {
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
		let modifiers = structDecl.modifiers
		return [try ExtensionDeclSyntax("""
			\(raw:modifiers) extension \(raw:structureName):RAW_staticbuff {
				typealias RAW_staticbuff_storetype = \(raw:generateTypeExpression(byteCount:Self.parseNumber(from:node)))
			}
			""")]
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		var logger = mainLogger
		logger[metadataKey: "mtype"] = "members"
		logger.info("running macro function on node '\(declaration.description).")
		defer {
			logger.info("macro function finished.")
		}
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			logger.critical("expected struct declaration")
			throw Diagnostics.mustBeIntegerLiteral("\(declaration)")
		}
		let structureName = structDecl.name
		logger.info("got structure name.", metadata:["structureName": "\(structureName)"])
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
		
		let initializer = DeclSyntax("""
			public init?(RAW_data:UnsafeRawPointer?) {
				guard RAW_data != nil else {
					return nil
				}
				self.fixedBuffer = RAW_data!.assumingMemoryBound(to:RAW_staticbuff_storetype.self).pointee
			}
			""")

		let asRawFunc = DeclSyntax("""
			func asRAW_val<R>(_ valFunc: (RAW) throws -> R) rethrows -> R {
				try withUnsafePointer(to:fixedBuffer) { ptr in
					return try valFunc(RAW(RAW_size: MemoryLayout<RAW_staticbuff_storetype>.size, RAW_data: ptr))
				}
			}
			""")
		var buildDecls = [DeclSyntax]()
		buildDecls.append(privateFixedBufferVal)
		buildDecls.append(initializer)
		buildDecls.append(asRawFunc)
		return buildDecls
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
