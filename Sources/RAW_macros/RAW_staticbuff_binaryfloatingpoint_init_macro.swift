import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:"RAW_staticbuff_binaryfloatingpoint_init_macro")
#endif

internal struct RAW_staticbuff_binaryfloatingpoint_init_macro:DeclarationMacro {
    static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		#if RAWDOG_MACRO_LOG
		mainLogger.info("expanding macro \(node)")
		#endif

		guard let parseNodeConfig = try? parseConfiguration(node:node, context:context) else {
			return []
		}

		return [DeclSyntax("""
				init(_ intStaticBuffType:\(raw:parseNodeConfig.structName)) {
					self = intStaticBuffType.RAW_access { ptr, _ in
						#if DEBUG
						assert(MemoryLayout<Self>.size == MemoryLayout<\(raw:parseNodeConfig.structName).RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
						#endif
						return Self(\(raw:parseNodeConfig.isBigEndian ? "bigEndian" : "littleEndian"):ptr.loadUnaligned(as:Self.self))
					}
				}
			""")
		]
    }

	
	private static func parseConfiguration(node:SyntaxProtocol, context:SwiftSyntaxMacros.MacroExpansionContext) throws -> (structName:String, isBigEndian:Bool) {
		class NodeSearcher:SyntaxVisitor {
			internal var foundType:IdentifierTypeSyntax? = nil
			internal var isBigEndian:Bool?

			override func visit(_ node:GenericArgumentClauseSyntax) -> SyntaxVisitorContinueKind {
				guard node.arguments.count == 1 else {
					#if RAWDOG_MACRO_LOG
					mainLogger.error("expected 2 generic arguments, found \(node.arguments.count)")
					#endif
					return .skipChildren
				}
				let argSearcher = SingleTypeGenericArgumentFinder(viewMode:.sourceAccurate)
				argSearcher.walk(node)
				foundType = argSearcher.foundType
				return .visitChildren
			}
			
			override func visit(_ node:LabeledExprListSyntax) -> SyntaxVisitorContinueKind {
				guard node.count == 1 else {
					#if RAWDOG_MACRO_LOG
					mainLogger.error("expected 1 labeled expression, found \(node.count)")
					#endif
					return .skipChildren
				}
				return .visitChildren
			}

			override func visit(_ node:LabeledExprSyntax) -> SyntaxVisitorContinueKind {
				guard node.label?.text == "bigEndian" else {
					#if RAWDOG_MACRO_LOG
					mainLogger.error("expected labeled expression to be named \"bigEndian\", found \(String(describing:node.label?.text))")
					#endif
					return .skipChildren
				}
				return .visitChildren
			}
			override func visit(_ node:BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind {
				isBigEndian = node.literal.text == "true"
				return .visitChildren
			}
		}

		let argSearcher = NodeSearcher(viewMode:.sourceAccurate)
		argSearcher.walk(node)
		guard let foundType = argSearcher.foundType else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("missing generic argument")
			#endif
			context.addDiagnostics(from:Diagnostics.missingGenericArgument, node:node)
			throw Diagnostics.missingGenericArgument
		}
		guard let isBigEndian = argSearcher.isBigEndian else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("missing bigEndian argument")
			#endif
			throw Diagnostics.missingGenericArgument
		}

		return (foundType.name.text, isBigEndian)
	}

	public enum Diagnostics:Swift.Error, DiagnosticMessage {
		case missingGenericArgument

		/// the severity of the diagnostic.
		public var severity:DiagnosticSeverity {
			return .error
		}

		public var did:String {
			switch self {
				case .missingGenericArgument:
					return "missingGenericArgument"
			}
		}

		public var message:String {
			switch self {
				case .missingGenericArgument:
					return "missing generic argument specifying the BinaryFloatingPoint type to bridge to."
			}
		}

		public var diagnosticID:MessageID {
			return MessageID(domain:"RAW_staticbuff_binaryfloatingpoint_init_macro", id:self.did)
		}
	}
}