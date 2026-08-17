// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

extension RAW_macros.RAW_fixed_protocol {
	internal struct BytesMacro:ExtensionMacro, DeclarationMacro {
	    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
	        guard node.arguments.count == 1 else {
				// if there are not exactly one argument in the macro, we should not generate any code.
				return []
			}

			let numberOfBytes = RAW_macro_validators.validateRAW_fixed_byte_argument(labeledExpression:node.arguments.first!, context:context) ?? 0
			return [
				DeclSyntax("typealias RAW_fixed_type = \(generateUnsignedByteTypeExpression(byteCount:numberOfBytes))")
			]
	    }

		internal struct MismatchedByteCount:Swift.Error, SwiftDiagnostics.DiagnosticMessage {
			internal var message:String { "the byte count argument in the #RAW_fixed_type macro does not match the byte count argument in this macro. expected \(expectedByteCount), found \(foundByteCount)." }
			internal var diagnosticID: SwiftDiagnostics.MessageID = SwiftDiagnostics.MessageID(domain:"\(String(describing: RAW_macros.RAW_fixed_protocol.BytesMacro.self))", id: "\(String(describing: Self.self))")
			internal var severity: SwiftDiagnostics.DiagnosticSeverity = .error
			internal let expectedByteCount:Int
			internal let foundByteCount:Int
		}
		internal struct UnconfirmedByteSize:Swift.Error, SwiftDiagnostics.DiagnosticMessage {
			internal var message:String { "the byte count argument in the #RAW_fixed_type macro could not be confirmed to match the byte count argument in this macro. expected \(expectedByteCount). implement the conformance of `RAW_fixed` on this member to resolve this error." }
			internal var diagnosticID: SwiftDiagnostics.MessageID = SwiftDiagnostics.MessageID(domain:"\(String(describing: RAW_macros.RAW_fixed_protocol.BytesMacro.self))", id: "\(String(describing: Self.self))")
			internal var severity: SwiftDiagnostics.DiagnosticSeverity = .error
			internal let expectedByteCount:Int
		}
		public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
			guard case let .argumentList(args) = node.arguments, args.count == 1 else {
				// if there are not exactly one argument in the macro, we should not generate any code.
				return []
			}

			var returnValues = [SwiftSyntax.ExtensionDeclSyntax]()
			let correctByteCount = RAW_macro_validators.validateRAW_fixed_byte_argument(labeledExpression:args.first!, context:context) ?? 0
			var implemented:Set<String> = []

			// if there are no protocols in the extension declaration, we should not generate any code.
			seekLoop: for proto in protocols {
				defer {
					implemented.insert(proto.trimmedDescription)
				}
				switch proto.trimmedDescription {
					case "RAW_fixed":
							returnValues += [
								try! ExtensionDeclSyntax(
									"""
									extension \(raw:type.trimmedDescription):\(raw:proto.trimmedDescription) {
										#RAW_fixed_type(bytes:\(raw:correctByteCount))
									}
									"""
								)
							]
					default:
						// if the macro is attached to an extension declaration that does not conform to "RAW_fixed", we should not generate any code.
						continue seekLoop
				}
			}

			if implemented.contains("RAW_fixed") == false {
				// indicates that the user already implemented this macro themselves, so now the goal is to validate that the inner usage of the #RAW_fixed_type macro matches the expected format as configured by this macro.

				// scan the body to determine if the #RAW_fixed_type macro is being used, if it is not being used, then we should not generate any code.
				let macroSearcher = Freestanding_macro_searcher(expectedMacroName:"RAW_fixed_type", viewMode:.fixedUp)
				macroSearcher.walk(declaration)
				if macroSearcher.foundMacro != nil && macroSearcher.foundMacro!.count == 1 {
					// audit the usage of the inner freestanding expression macro to ensure it matches the expected format as configured by this macro.
					let foundMacroArgument = macroSearcher.foundMacro!.first!
					let potentiallyIncorrectByteCount = RAW_macro_validators.validateRAW_fixed_byte_argument(labeledExpression:foundMacroArgument, context:context)
					guard potentiallyIncorrectByteCount == correctByteCount else {
						let diag = Diagnostic(node:foundMacroArgument.expression, message:MismatchedByteCount(expectedByteCount:correctByteCount, foundByteCount:potentiallyIncorrectByteCount ?? -1))
						context.diagnose(diag)
						return []
					}
					// no need to implement because the user has expressed their own macro here. the two macros agree in configuration.
				} else {
					let diag = Diagnostic(node:args, message:UnconfirmedByteSize(expectedByteCount:correctByteCount))
					context.diagnose(diag)
					return []
				}
			}
			return returnValues
		}
	}
}