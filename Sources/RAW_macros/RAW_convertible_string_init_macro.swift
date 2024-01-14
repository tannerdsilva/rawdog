import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

fileprivate let domain = "RAW_convertible_string_init_macro"
#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:domain)
#endif

internal struct RAW_convertible_string_init_macro:DeclarationMacro {
    static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		#if RAWDOG_MACRO_LOG
		mainLogger.info("expanding macro \(node)")
		#endif

		let parseNodeConfig = try parseConfiguration(node:node, context:context)

		return [DeclSyntax("""
				init(_ strType:\(raw:parseNodeConfig)) {
					self = Self.decodeCString(strType.bytes, as:\(raw:parseNodeConfig).RAW_convertible_unicode_encoding.self, repairingInvalidCodeUnits:true)!.result
				}
			""")
		]
    }

	private static func parseConfiguration(node:SyntaxProtocol, context:SwiftSyntaxMacros.MacroExpansionContext) throws -> String {
		class NodeSearcher:SyntaxVisitor {
			internal var extendedType:IdentifierTypeSyntax? = nil

			override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
				guard node.count == 1 else {
					#if RAWDOG_MACRO_LOG
					mainLogger.error("expected 2 generic arguments, found \(node.count)")
					#endif
					return .skipChildren
				}
				let idLister = IdTypeLister(viewMode:.sourceAccurate)
				idLister.walk(node)
				extendedType = idLister.listedIDTypes.first
				return .skipChildren
			}
		}

		let argSearcher = NodeSearcher(viewMode:.sourceAccurate)
		argSearcher.walk(node)
		guard let extendedType = argSearcher.extendedType else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("could not find extended type")
			#endif
			throw Diagnostics.missingGenericArgument
		}
		return (extendedType.name.text)
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
					return "RAW_staticbuff_binaryinteger_macro.missing_generic_argument"
			}
		}

		public var message:String {
			switch self {
				case .missingGenericArgument:
					return "missing generic argument specifying the integer type to bridge to."
			}
		}

		public var diagnosticID:MessageID {
			return MessageID(domain:"RAW_staticbuff_binaryinteger_macro", id:self.did)
		}
	}
}