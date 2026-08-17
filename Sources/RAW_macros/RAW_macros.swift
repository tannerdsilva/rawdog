import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

internal final class Freestanding_macro_searcher:SyntaxVisitor {
	internal var foundMacro:LabeledExprListSyntax? = nil
	internal let expectedMacroName:String
	internal init(expectedMacroName:String, viewMode:SyntaxTreeViewMode) {
		self.expectedMacroName = expectedMacroName
		super.init(viewMode:viewMode)
	}
	internal override func visit(_ node:MacroExpansionDeclSyntax) -> SyntaxVisitorContinueKind {
		guard node.macroName.text == expectedMacroName && foundMacro == nil else {
			return .visitChildren
		}
		foundMacro = node.arguments
		return .skipChildren
	}
}

internal struct InternalMacroFailure:Swift.Error, SwiftDiagnostics.DiagnosticMessage {
	internal let message:String
	internal let diagnosticID:SwiftDiagnostics.MessageID = SwiftDiagnostics.MessageID(domain:"RAW_macros", id:"InternalMacroFailure")
	internal let severity:SwiftDiagnostics.DiagnosticSeverity = .error
	internal init(message:String) {
		self.message = message
	}
}

// thrown when a type expression is found where the macro expects 'Self.self'.
internal struct TypeMustBeSelfFailure:Swift.Error, DiagnosticMessage {
    internal let found:String
    internal var message:String {
        // "type must be 'Self.self', but 'BlackjackCard.self' was provided."
        "type must be 'Self.self', but '\(found)' was provided."
    }
    internal let diagnosticID:MessageID = MessageID(domain: "RAW_macros", id: "type_must_be_self")
    internal let severity:DiagnosticSeverity = .error
    
    internal struct FixIt:FixItMessage {
        // direct instruction to the user to replace the incorrect value.
        internal let message:String = "replace with 'Self.self'."
        internal let fixItID:SwiftDiagnostics.MessageID = MessageID(domain: "RAW_macros", id: "type_must_be_self_fix")
    }
}

internal func generateUnsignedByteTypeExpression(byteCount:Int) -> SwiftSyntax.TupleTypeSyntax {
	return generateTypeExpression(typeSyntax:IdentifierTypeSyntax(name:.identifier("UInt8")), byteCount:byteCount)
}
fileprivate func generateTypeExpression(typeSyntax:IdentifierTypeSyntax, byteCount:Int) -> SwiftSyntax.TupleTypeSyntax {
	var buildContents = TupleTypeElementListSyntax()
	var i:Int = 0
	while i < byteCount {
		var byteTypeElement = TupleTypeElementSyntax(type:typeSyntax)
		byteTypeElement.trailingComma = (i + 1 < byteCount) ? TokenSyntax.commaToken(trailingTrivia:.space) : nil
		buildContents.append(byteTypeElement)
		i += 1
	}
	return TupleTypeSyntax(leftParen:TokenSyntax.leftParenToken(), elements:buildContents, rightParen:TokenSyntax.rightParenToken())
}