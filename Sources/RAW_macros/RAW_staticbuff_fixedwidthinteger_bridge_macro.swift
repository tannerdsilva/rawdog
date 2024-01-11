import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:"RAW_staticbuff_fixedwidthinteger_bridge_macro")
#endif

internal struct RAW_staticbuff_fixedwidthinteger_bridge_macro:ExpressionMacro {
	static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
		#if RAWDOG_MACRO_LOG
		mainLogger.notice("expanding macro \(node)")
		#endif
		// fatalError()
		let config = try parseConfiguration(node:node)
		// fatalError()
		return ExprSyntax("""
			extension \(raw:config.intName) {
				// public init(_ value:\(raw:config.staticImplName)) {
				// 	value.RAW_access { ptr in
				// 		return Self()
				// 	}
				// }

				public static func KMS() -> Int {
					fatalError()
				}
			}
		""")
	}


	private static func parseConfiguration(node:SyntaxProtocol) throws -> (intName:String, staticImplName:String, isBigEndian:Bool) {
		class MacroExpansionContext:SyntaxVisitor {
			internal var genericArguments:[GenericArgumentSyntax] = []
			internal var isBigEndian:Bool?

			override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
				guard node.count == 2 else {
					#if RAWDOG_MACRO_LOG
					mainLogger.error("expected 2 generic arguments, found \(node.count)")
					#endif
					return .skipChildren
				}
				return .visitChildren
			}

			override func visit(_ node:GenericArgumentSyntax) -> SyntaxVisitorContinueKind {
				genericArguments.append(node)
				return .visitChildren
			}
		}

		let argSearcher = MacroExpansionContext(viewMode:.sourceAccurate)
		argSearcher.walk(node)
		guard argSearcher.genericArguments.count == 2 else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected 2 generic arguments, found \(argSearcher.genericArguments.count)")
			#endif
			fatalError()
		}
		guard let intName = argSearcher.genericArguments[0].argument.as(IdentifierTypeSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected first generic argument to be an identifier, found \(type(of:argSearcher.genericArguments[0].argument))")
			#endif
			fatalError()
		}
		#if RAWDOG_MACRO_LOG
		mainLogger.notice("intName: \(intName)")
		#endif
		guard let staticImplName = argSearcher.genericArguments[1].argument.as(IdentifierTypeSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected second generic argument to be an identifier, found \(type(of:argSearcher.genericArguments[1].argument))")
			#endif
			fatalError()
		}
		#if RAWDOG_MACRO_LOG
		mainLogger.notice("staticImplName: \(staticImplName)")
		#endif
		return (intName.name.text, staticImplName.name.text, false)
	}
	
}