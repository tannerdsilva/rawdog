import SwiftCompilerPlugin
import SwiftSyntaxMacros
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics


@main
struct RAW_macros:CompilerPlugin {
	let providingMacros:[Macro.Type] = [
		RAW_convertible_string_init_macro.self,
		RAW_convertible_string_type_macro.self,

		RAW_staticbuff_binaryfloatingpoint_init_macro.self,
		RAW_staticbuff_floatingpoint_type_macro.self,

		RAW_staticbuff_fixedwidthinteger_bridge_macro.self,
		RAW_staticbuff_fixedwidthinteger_type_macro.self,
		
		RAW_staticbuff_macro.self,
		RAW_staticbuff_concat_type_macro.self,
	]
}

internal struct ExpectedStructAttachment:Swift.Error, DiagnosticMessage {
	private let foundType:SyntaxProtocol.Type
	internal var message:String { "this macro expects to be attached to a struct declaration. instead, found type \(String(describing:foundType))." }
	internal var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"expected_struct_attachment")}
	internal var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
	internal init(found:SyntaxProtocol.Type) {
		self.foundType = found
	}
}


// captures all of the identifier types.
internal class IdTypeLister:SyntaxVisitor {
	internal var listedIDTypes:Set<IdentifierTypeSyntax> = []
	override func visit(_ node:IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
		listedIDTypes.insert(node)
		return .skipChildren
	}
}

// captures the single identifier type listed in a generic argument clause.
internal class SingleTypeGenericArgumentFinder:SyntaxVisitor {
	internal var foundType:IdentifierTypeSyntax? = nil
	override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
		guard node.count == 1 else {
			return .skipChildren
		}
		let idScanner = IdTypeLister(viewMode:.sourceAccurate)
		idScanner.walk(node)
		foundType = idScanner.listedIDTypes.first
		return .skipChildren
	}
}

internal func generateUnsignedByteTypeExpression(byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	return generateTypeExpression(typeSyntax:IdentifierTypeSyntax(name:.identifier("UInt8")), byteCount:byteCount)
}
fileprivate func generateTypeExpression(typeSyntax:IdentifierTypeSyntax, byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	var buildContents = TupleTypeElementListSyntax()
	var i:UInt16 = 0
	while i < byteCount {
		var byteTypeElement = TupleTypeElementSyntax(type:typeSyntax)
		byteTypeElement.trailingComma = i + 1 < byteCount ? TokenSyntax.commaToken() : nil
		buildContents.append(byteTypeElement)
		i += 1
	}
	return TupleTypeSyntax(leftParen:TokenSyntax.leftParenToken(), elements:buildContents, rightParen:TokenSyntax.rightParenToken())
}
