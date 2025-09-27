// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

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
	// thrown when the macro is applied to a struct that is a staticbuff "concat" variant instead of a byte count variant.
	internal struct InvalidStaticbuffMode:Swift.Error, DiagnosticMessage {
		public var message:String { return "expected the macro to be applied to a staticbuff byte count variant, but applied configuration for a concat variant" }
		public var severity:DiagnosticSeverity { return .error }
		public var diagnosticID:MessageID { return MessageID(domain:"RAW_staticbuff_floatingpoint_type_macro", id:"invalidStaticbuffMode") }
	}

	// thrown when the macro is applied and a boolean expression is provided as bigEndian, but the expression is not a boolean literal.
	internal struct MustBeBooleanLiteral:Swift.Error, DiagnosticMessage {
		public var message:String { return "expected the macro to be applied with a boolean literal as the bigEndian argument, but found a non-literal expression" }
		public var severity:DiagnosticSeverity { return .error }
		public var diagnosticID:MessageID { return MessageID(domain:"RAW_staticbuff_floatingpoint_type_macro", id:"mustBeBooleanLiteral") }
	}

	private class NodeConfigParser:SyntaxVisitor {
		var intType:IdentifierTypeSyntax? = nil
		var bigEndianBoolExpr:ExprSyntax? = nil
		override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
			let idScanner = IdTypeLister(viewMode:.sourceAccurate)
			idScanner.walk(node)
			intType = idScanner.listedIDTypes.first
			return .skipChildren
		}
		override func visit(_ node:LabeledExprSyntax) -> SyntaxVisitorContinueKind {
			guard node.label?.text == "bigEndian" else {
				return .skipChildren
			}
			bigEndianBoolExpr = node.expression
			return .skipChildren
		}
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, conformingTo protocols:[TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		let rsbNodeParser = RAW_staticbuff.SyntaxFinder(viewMode: .sourceAccurate)
		rsbNodeParser.walk(declaration)
		guard let foundStaticBuffMacro = rsbNodeParser.found else {
			return []
		}
		guard let mode = rsbNodeParser.usageMode else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected mode to be set '\(node)'")
			#endif
			return []
		}
		guard case .bytes(let byteLength) = mode else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected mode to be set to bytes, found \(mode)")
			#endif
			context.addDiagnostics(from:InvalidStaticbuffMode(), node:foundStaticBuffMacro)
			return []
		}

		#if RAWDOG_MACRO_LOG
		mainLogger.debug("member macro initiated - detected mode: \(mode)")
		#endif

		let structFinder = StructFinder(viewMode: .sourceAccurate)
		structFinder.walk(declaration)
		guard let asStruct = structFinder.structDecl else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected struct declaration, found \(String(describing:declaration.syntaxNodeType))")
			#endif
			context.addDiagnostics(from:ExpectedStructAttachment(found:declaration.syntaxNodeType), node:node)
			return []
		}

		let loadFuncName = byteLength == 1 ? "load" : "loadUnaligned"

		let nodeconfigparse = NodeConfigParser(viewMode:.sourceAccurate)
		nodeconfigparse.walk(node)
		guard	let intType = nodeconfigparse.intType else {
			return []
		}
		guard let nodeconfigparse = nodeconfigparse.bigEndianBoolExpr else {
			return []
		}
		guard let bigEndianBoolExpr = nodeconfigparse.as(BooleanLiteralExprSyntax.self) else {
			context.addDiagnostics(from:MustBeBooleanLiteral(), node:nodeconfigparse)
			return []
		}
		let asBool = Bool(bigEndianBoolExpr.literal.text)!
		let nativeTranslatorName = asBool == true ? "bigEndian" : "littleEndian"

		let compareFunction = DeclSyntax("""
			\(asStruct.modifiers) static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
				let lhs = \(raw:intType)(\(raw:nativeTranslatorName):lhs_data.\(raw:loadFuncName)(as:\(raw:intType).self))
				let rhs = \(raw:intType)(\(raw:nativeTranslatorName):rhs_data.\(raw:loadFuncName)(as:\(raw:intType).self))
				if lhs < rhs {
					return -1
				} else if lhs > rhs {
					return 1
				} else {
					return 0
				}
			}
		""")

		let nativeGet = DeclSyntax("""
			\(asStruct.modifiers) func RAW_native() -> \(raw:intType) {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<\(raw:intType)>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to:self) { selfPtr in
					return \(raw:intType)(\(raw:nativeTranslatorName):UnsafeRawPointer(selfPtr).\(raw:loadFuncName)(as:\(raw:intType).self))
				}
			}
		""")

		let nativeInit = DeclSyntax("""
			\(asStruct.modifiers) init(RAW_native native:\(raw:intType)) {
				#if DEBUG
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<RAW_native_type>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				var enc = native.\(raw:nativeTranslatorName)
				self.init(RAW_staticbuff:&enc)
			}
		""")

		return [
			compareFunction,
			nativeGet,
			nativeInit
		]
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		let structFinder = StructFinder(viewMode: .sourceAccurate)
		structFinder.walk(declaration)
		guard structFinder.structDecl != nil else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected struct declaration, found \(String(describing:declaration.syntaxNodeType))")
			#endif
			return []
		}

		// verify the type is sendable before adding the conformance.
		guard isMarkedSendable(structFinder.structDecl!) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected struct to be marked Sendable")
			#endif
			return []
		}
		
		return [try! ExtensionDeclSyntax("""
			extension \(type):RAW_encoded_fixedwidthinteger {}
		""")]
	}
}