import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:"RAW_val_concat")
#endif

public struct GenerateByteTuple:ExpressionMacro {
    public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {
		let newNumber = try parseNumber(from:node)
		var buildRestult = "("
		for i in 0..<newNumber {
			buildRestult += "0 as UInt8"
			if i != newNumber - 1 {
				buildRestult += ", "
			}
		}
		return ExprSyntax("""
			\(raw:buildRestult)
		""")
    }

	public enum Diagnostics:Swift.Error, DiagnosticMessage {
		/// thrown when a type of syntax is expected but a different type is found.
		/// - parameter expected: the type of syntax expected.
		/// - parameter found: the type of syntax found.
		case unexpectedSyntaxStructure(SyntaxProtocol.Type, SyntaxProtocol.Type)

		/// thrown when the attached declaration is not a struct or class.
		case invalidAttachedDeclaration

		/// thrown when the number of members in the attribute does not match the number of members in the attached declaration.
		case incorrectMemberCount(expected:Int, found:Int)

		/// thrown when the type of a member in the attribute does not match the type of the member in the attached declaration.
		case incorrectMemberType(expected:String, found:String)

		public var severity:DiagnosticSeverity {
			return .error
		}

		public var did:String {
			switch self {
				case .unexpectedSyntaxStructure(_, _):
					return "RAW_val_concat.unexpectedSyntaxStructure"
				case .invalidAttachedDeclaration:
					return "RAW_val_concat.invalidAttachedDeclaration"
				case .incorrectMemberCount(_, _):
					return "RAW_val_concat.incorrectMemberCount"
				case .incorrectMemberType(_, _):
					return "RAW_val_concat.incorrectMemberType"
			}
		}

		public var message:String {
			switch self {
				case .unexpectedSyntaxStructure(let expected, let found):
					return "this macro expects \(expected) but found \(found)."
				case .invalidAttachedDeclaration:
					return "this macro expects the attached declaration to be a struct or class."
				case .incorrectMemberCount(let expected, let found):
					return "this macro expects \(expected) members but found \(found)."
				case .incorrectMemberType(let expected, let found):
					return "this macro expects member type \(expected) but found \(found)."
			}
		}

		public var diagnosticID:MessageID {
			return MessageID(domain:"RAW_macros", id:self.did)
		}
	}

	/// parses the static buffer number from the attribute node.
	fileprivate static func parseNumber(from node:SwiftSyntax.FreestandingMacroExpansionSyntax) throws -> UInt16 {
		#if RAWDOG_MACRO_LOG
		mainLogger.info("parsing attribute number.")
		defer {
			mainLogger.info("finished parsing attribute number.")
		}
		#endif
		let attributeNumber = node.as(LabeledExprListSyntax.self)?.first?.expression.as(IntegerLiteralExprSyntax.self)?.literal
		let getNewNumber:UInt16?
		switch attributeNumber {
			case .some(let number):
				guard case .integerLiteral(let value) = number.tokenKind else {
					#if RAWDOG_MACRO_LOG
					mainLogger.critical("expected integer literal")
					#endif
					throw Diagnostics.invalidAttachedDeclaration
				}
				getNewNumber = UInt16(value)
			case .none:
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("expected integer literal")
				#endif
				throw Diagnostics.invalidAttachedDeclaration
		}
		#if RAWDOG_MACRO_LOG
		mainLogger.info("got attribute number", metadata:["attributeNumber": "\(String(describing: getNewNumber!))"])
		#endif
		let newNumber = getNewNumber!
		return newNumber
	}
}