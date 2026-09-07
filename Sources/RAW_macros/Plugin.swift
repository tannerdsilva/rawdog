// LICENSE MIT
// copyright (c) tanner silva 2026. all rights reserved.

import SwiftCompilerPlugin
import SwiftSyntaxMacros
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

@main
struct MainPlugin:CompilerPlugin {
	let providingMacros:[Macro.Type] = [
		RAW_fixed_protocol.BytesMacro.self,
		RAW_fixed_protocol.ConcatMacro.self,
		RAW_decodable_protocol.DecodeMacro.self,
		RAW_staticbuff_macro.BytesMacro.self,
		RAW_staticbuff_macro.ConcatMacro.self,
		RAW_staticbuff_protocol.InitMacro.self,
		RAW_staticbuff_access_decl.self,
		RAW_staticbuff_access_mutating_decl.self,
		RAW_staticbuff_encode_count_decl.self,
		RAW_staticbuff_encode_decl.self,
		RAW_accessible_protocol.MutableMacro.self,
		RAW_encodable_count_fixed_macro.self,
		RAW_encodable_protocol.DataMacro.self,
		RAW_accessible_protocol.ImmutableMacro.self,
		RAW_staticbuff_fixedwidthinteger_type_macro.self,
		RAW_staticbuff_binaryfloatingpoint_type_macro.self,
		RAW_convertible_string_type_macro.self
	]
}
internal struct RAW_macro_validators {
	internal static func validateRAW_fixed_byte_argument(labeledExpression:LabeledExprSyntax, context:SwiftSyntaxMacros.MacroExpansionContext) -> Int? {
		let base10IntegerLiteralArgumentValidator = RAW_fixed_protocol.RAW_fixed_bytes_argument_validator(context:context)
		base10IntegerLiteralArgumentValidator.walk(labeledExpression)
		return base10IntegerLiteralArgumentValidator.numberOfBytes
	}
	internal static func validateRAW_keypath_argument(labeledExpression:LabeledExprSyntax, context:SwiftSyntaxMacros.MacroExpansionContext) -> [DeclReferenceExprSyntax]? {
		let keyPathArgumentValidator = RAW_fixed_protocol.RAW_macros_keypath_argument_validator(context:context)
		keyPathArgumentValidator.walk(labeledExpression)
		return keyPathArgumentValidator.keyPathComponents
	}
}
