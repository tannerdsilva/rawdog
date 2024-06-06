// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:"RAW_staticbuff_floatingpoint_type_macro")
#endif

fileprivate let typeBitpatternTypes:[String:String] = ["Double":"UInt64", "Float":"UInt32"]
fileprivate let typeBitNames:[String:String] = ["Double":"bitPattern", "Float":"bitPattern"]

internal struct RAW_staticbuff_floatingpoint_type_macro:MemberMacro, ExtensionMacro {
	// thrown when the macro is applied to a struct that is a staticbuff "concat" variant instead of a byte count variant.
	internal struct InvalidStaticbuffMode:Swift.Error, DiagnosticMessage {
		public var message:String { return "expected the macro to be applied to a staticbuff byte count variant, but applied configuration for a concat variant" }
		public var severity:DiagnosticSeverity { return .error }
		public var diagnosticID:MessageID { return MessageID(domain:"RAW_staticbuff_floatingpoint_type_macro", id:"invalidStaticbuffMode") }
	}

	private class NodeConfigParser:SyntaxVisitor {
		var floatType:IdentifierTypeSyntax? = nil
		override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
			let idScanner = IdTypeLister(viewMode:.sourceAccurate)
			idScanner.walk(node)
			floatType = idScanner.listedIDTypes.first
			return .skipChildren
		}
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		let nodeParser = RAW_staticbuff.SyntaxFinder(viewMode: .sourceAccurate)
		nodeParser.walk(declaration)
		guard let mode = nodeParser.usageMode, case .bytes(_) = mode else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected mode to be set '\(node)'")
			#endif
			context.addDiagnostics(from:ExpectedStructAttachment(found:node.syntaxNodeType), node:node)
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

		let nodeconfigparse = NodeConfigParser(viewMode:.sourceAccurate)
		nodeconfigparse.walk(node)
		guard	let floatType = nodeconfigparse.floatType,
				let bitPatternType = typeBitpatternTypes[floatType.name.text],
				let nativeTranslatorName = typeBitNames[floatType.name.text] else {
			return []
		}
		let compareFunction = DeclSyntax("""
			\(asStruct.modifiers) static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
				let lhs = \(raw:floatType)(\(raw:nativeTranslatorName):lhs_data.loadUnaligned(as:\(raw:bitPatternType).self))
				let rhs = \(raw:floatType)(\(raw:nativeTranslatorName):rhs_data.loadUnaligned(as:\(raw:bitPatternType).self))
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
			\(asStruct.modifiers) func RAW_native() -> \(raw:floatType) {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<\(raw:floatType)>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
				#endif
				return withUnsafePointer(to:self) { selfPtr in
					return \(raw:floatType)(\(raw:nativeTranslatorName):UnsafeRawPointer(selfPtr).loadUnaligned(as:\(raw:bitPatternType).self))
				}
			}
		""")

		let nativeInit = DeclSyntax("""
			\(asStruct.modifiers) init(RAW_native native:\(raw:floatType)) {
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

		guard isMarkedSendable(structFinder.structDecl!) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected struct to be marked Sendable")
			#endif
			return []
		}
		
		return [try! ExtensionDeclSyntax("""
			extension \(type):RAW_encoded_binaryfloatingpoint {}
		""")]
	}
}
