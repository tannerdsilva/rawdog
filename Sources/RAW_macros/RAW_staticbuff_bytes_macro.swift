// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

fileprivate struct NodeUsageDiagnostics {
	fileprivate struct ByteCountMissing:Swift.Error, DiagnosticMessage {
		public let message:String = "expected a zero or positive integer literal for the byte count, but found no integer literal."
		public let severity:DiagnosticSeverity = .error
		public let diagnosticID:MessageID = MessageID(domain:"RAW_staticbuff_bytes_macro", id:"byteCountMissing")
	}
	fileprivate struct InvalidByteCount:Swift.Error, DiagnosticMessage {
		public let message:String = "expected a zero or positive integer literal for the byte count, but found a negative integer literal."
		public let severity:DiagnosticSeverity = .error
		public let diagnosticID:MessageID = MessageID(domain:"RAW_staticbuff_bytes_macro", id:"invalidByteCount")
	}
}

fileprivate struct AttachedMemberDiagnostics {
	// diagnostic error that is thrown when the attached body could not be parsed effectively.
	fileprivate struct UnknownAttachedMemberType:Swift.Error, DiagnosticMessage {
		fileprivate let message:String
		fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_unidentified_type")
		fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		fileprivate init(found:SyntaxProtocol.Type) {
			self.message =  "could not determine the syntax that the macro was attached to. expected to find a struct declaration but found '\(String(describing:found))' instead."
		}
	}

	// message to notify the user that the attached member is not a struct.
	fileprivate struct IncorrectAttachedMemberType:DiagnosticMessage {
		fileprivate let foundType:AttachedMemberTypeIdentifier.AttachedType
		fileprivate let message:String
		fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_incorrect_type")
		fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		fileprivate init(found:AttachedMemberTypeIdentifier.AttachedType) {
			self.foundType = found
			switch found {
				case .classType(let classDecl):
					self.message = "attached member \(classDecl.name.text) is a class. expected to find a struct."
				case .protocolType(let protocolDecl):
					self.message = "attached member \(protocolDecl.name.text) is a protocol. expected to find a struct."
				case .enumType(let enumDecl):
					self.message = "attached member \(enumDecl.name.text) is an enum. expected to find a struct."
				case .structType(let structDecl):
					self.message = "attached member \(structDecl.name.text) is a struct. expected to find a struct."
			}
		}

		// fixit message to convert the attached member to a struct.
		fileprivate struct FixItDiagnostic:FixItMessage {
			fileprivate let message:String
			fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_fix_convert_to_struct_decl")
			fileprivate let fromOldType:AttachedMemberTypeIdentifier.AttachedType
			fileprivate init(fromOldType:AttachedMemberTypeIdentifier.AttachedType) {
				self.fromOldType = fromOldType
				switch fromOldType {
					case .classType(let classDecl):
						self.message = "convert \(classDecl.name.text) from class to struct."
					case .protocolType(let protocolDecl):
						self.message = "convert \(protocolDecl.name.text) from protocol to struct."
					case .enumType(let enumDecl):
						self.message = "convert \(enumDecl.name.text) from enum to struct."
					default:
						self.message = "convert unknown from struct to struct."
				}
			}
		}
	}
	
	// message to notify the user that private modifiers cannot be used on the attached member.
	fileprivate struct IncorrectAttachedMemberModifier:Swift.Error, DiagnosticMessage {
	    fileprivate let message:String
	    fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_incorrect_modifier")
	    fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		fileprivate init(unsupportedModifier:DeclModifierSyntax) {
			self.message = "'\(unsupportedModifier.name.text)' modifier is not supported. please remove this modifier from the attached member and consider using a modifier such as 'fileprivate' or 'internal' to manage access."
		}
		
		fileprivate struct FixItDiagnostic:FixItMessage {
			fileprivate let message:String
			fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_fix_incorrect_modifier")
			fileprivate init(replace:DeclModifierSyntax, withSyntax:DeclModifierSyntax?) {
				self.message = "replace \(replace.name.text) modifier with \(withSyntax?.name.text ?? "nothing")."
			}
		}
	}

	fileprivate struct StructMustBeSendable:DiagnosticMessage {
		fileprivate let message:String = "the attached struct must be marked as Sendable to use this macro."
		fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_struct_must_be_sendable")
		fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		fileprivate struct FixItDiagnostic:FixItMessage {
			fileprivate let message:String = "add Sendable inheritance."
			fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"attached_member_fix_struct_must_be_sendable")
		}
	}

	fileprivate static func validateAttachedMemberBasics(declaration:some SwiftSyntax.DeclGroupSyntax, node:SwiftSyntax.AttributeSyntax, context:some SwiftSyntaxMacros.MacroExpansionContext, addDiagnostics:Bool) -> StructDeclSyntax? {
		// parse for the attached declaration. the attached declaration must be a struct. if the attached syntax is not a struct declaration, offer valid suggestions to convert it to a struct.
		let typeIdentifier = AttachedMemberTypeIdentifier(viewMode:.sourceAccurate)
		typeIdentifier.walk(declaration)
		let asStruct:StructDeclSyntax
		switch typeIdentifier.foundType {
			case nil:
				if addDiagnostics == true {
					context.addDiagnostics(from:AttachedMemberDiagnostics.UnknownAttachedMemberType(found:declaration.syntaxNodeType), node:node)
				}
				return nil
			case .some(let id):
				switch id {
					case .structType(let structDecl):
						// if the attached declaration is a struct, then we can use it after doing some validation.

						// validate that the attached struct does not have a private modifier.
						var containsPrivate:DeclModifierSyntax? = nil
						for mod in structDecl.modifiers {
							if mod.name.text == "private" {
								containsPrivate = mod
							}
						}
						if containsPrivate != nil {
							// private modifier found. this is not allowed.
							if addDiagnostics == true {
								let internalDecl = DeclModifierSyntax(name:"internal", trailingTrivia:.space)
								let fileprivateDecl = DeclModifierSyntax(name:"fileprivate", trailingTrivia:.space)
								let publicDecl = DeclModifierSyntax(name:"public", trailingTrivia:.space)
								let diagnosticMessage = Diagnostic(
									node:containsPrivate!,
									message:AttachedMemberDiagnostics.IncorrectAttachedMemberModifier(unsupportedModifier:containsPrivate!),
									fixIts:[
										.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberModifier.FixItDiagnostic(replace:containsPrivate!, withSyntax:nil), oldNode:containsPrivate!, newNode:DeclSyntax("")),
										.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberModifier.FixItDiagnostic(replace:containsPrivate!, withSyntax:fileprivateDecl), oldNode:containsPrivate!, newNode:fileprivateDecl),
										.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberModifier.FixItDiagnostic(replace:containsPrivate!, withSyntax:internalDecl), oldNode:containsPrivate!, newNode:internalDecl),
										.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberModifier.FixItDiagnostic(replace:containsPrivate!, withSyntax:publicDecl), oldNode:containsPrivate!, newNode:publicDecl)
									]
								)
								context.diagnose(diagnosticMessage)
							}
							return nil
						}
						
						// verify that the struct is marked as Sendable. offer a fix to add sendable in the inheritance clause if it is not found.
						guard let inheritanceClauseTypes = structDecl.inheritanceClause?.inheritedTypes, inheritanceClauseTypes.count > 0 else {
							if addDiagnostics == true {
								var structDeclModify = structDecl
								structDeclModify.inheritanceClause = InheritanceClauseSyntax(colon:TokenSyntax(":"), inheritedTypes:InheritedTypeListSyntax([InheritedTypeSyntax(type:IdentifierTypeSyntax(name:TokenSyntax("Sendable"), trailingTrivia:.space))]))
								let diagnosticMessage = Diagnostic(
									node:structDecl.name,
									message:AttachedMemberDiagnostics.StructMustBeSendable(),
									fixIts:[
										.replace(message:AttachedMemberDiagnostics.StructMustBeSendable.FixItDiagnostic(), oldNode:structDecl, newNode:structDeclModify)
									]
								)
								context.diagnose(diagnosticMessage)
							}
							return nil
						}
						var foundSendable = false
						var rebuiltForAppendedSendable:InheritanceClauseSyntax = InheritanceClauseSyntax(colon:.colonToken(), inheritedTypes:[])
						searchLoop: for var inhType in inheritanceClauseTypes {
							if inhType.type.as(IdentifierTypeSyntax.self)?.name.text == "Sendable" {
								foundSendable = true
								break searchLoop
							}
							inhType.trailingTrivia = ""
							inhType.trailingComma = TokenSyntax(", ")
							rebuiltForAppendedSendable.inheritedTypes.append(inhType)
						}
						guard foundSendable == true else {
							// sendable not found. add it to the inheritance clause.
							if addDiagnostics == true {
								rebuiltForAppendedSendable.inheritedTypes.append(InheritedTypeSyntax(type:IdentifierTypeSyntax(name:TokenSyntax("Sendable"), trailingTrivia:.space)))
								var structDeclModify = structDecl
								structDeclModify.inheritanceClause = rebuiltForAppendedSendable
								let diagnosticMessage = Diagnostic(
									node:structDecl,
									message:AttachedMemberDiagnostics.StructMustBeSendable(),
									fixIts:[
										.replace(message:AttachedMemberDiagnostics.StructMustBeSendable.FixItDiagnostic(), oldNode:structDecl, newNode:structDeclModify)
									]
								)
								context.diagnose(diagnosticMessage)
							}
							return nil
						}

						// basic struct validation complete.
						asStruct = structDecl
						break
					case .classType(let classDecl):
						// attached class type. need to diagnose then return
						var replacementSyntax = StructDeclSyntax(attributes:classDecl.attributes, modifiers:classDecl.modifiers, name:classDecl.name, genericParameterClause:classDecl.genericParameterClause, inheritanceClause:classDecl.inheritanceClause, memberBlock:classDecl.memberBlock, trailingTrivia:Trivia.space)
						replacementSyntax.structKeyword.trailingTrivia = .space
						if addDiagnostics == true {
							let diagnosticMessage = Diagnostic(
								node:classDecl.name,
								message:AttachedMemberDiagnostics.IncorrectAttachedMemberType(found:typeIdentifier.foundType!),
								fixIts:[
									.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberType.FixItDiagnostic(fromOldType:id), oldNode:classDecl, newNode:replacementSyntax),
								]
							)
							context.diagnose(diagnosticMessage)
						}
						return nil
					case .protocolType(let protocolDecl):
						// attached protocol type. need to diagnose then return
						var replacementSyntax = StructDeclSyntax(attributes:protocolDecl.attributes, modifiers:protocolDecl.modifiers, name:protocolDecl.name, inheritanceClause:protocolDecl.inheritanceClause, memberBlock:protocolDecl.memberBlock, trailingTrivia:Trivia.space)
						replacementSyntax.structKeyword.trailingTrivia = .space
						if addDiagnostics == true {
							let diagnosticMessage = Diagnostic(
								node:protocolDecl.name,
								message:AttachedMemberDiagnostics.IncorrectAttachedMemberType(found:typeIdentifier.foundType!),
								fixIts:[
									.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberType.FixItDiagnostic(fromOldType:id), oldNode:protocolDecl, newNode:replacementSyntax),
								]
							)
							context.diagnose(diagnosticMessage)
						}
						return nil
					case .enumType(let enumDecl):
						// attached enum type. need to diagnose then return
						var replacementSyntax = StructDeclSyntax(modifiers:enumDecl.modifiers, name:enumDecl.name, inheritanceClause:enumDecl.inheritanceClause, memberBlock:enumDecl.memberBlock, trailingTrivia:Trivia.space)
						replacementSyntax.structKeyword.trailingTrivia = .space
						if addDiagnostics == true {
							let diagnosticMessage = Diagnostic(
								node:enumDecl.name,
								message:AttachedMemberDiagnostics.IncorrectAttachedMemberType(found:typeIdentifier.foundType!),
								fixIts:[
									.replace(message:AttachedMemberDiagnostics.IncorrectAttachedMemberType.FixItDiagnostic(fromOldType:id), oldNode:enumDecl, newNode:replacementSyntax),
								]
							)
							context.diagnose(diagnosticMessage)
						}
						return nil
				}
		}
		return asStruct
	}

	fileprivate struct MemberContentDiagnostics {
		fileprivate struct VariableInitializationUnsupported:DiagnosticMessage {
			fileprivate let message:String = "variable initialization not supported. please modify this variable expression to not have an initializer."
			fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_variable_initialization_unsupported")
			fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
			fileprivate struct FixItDiagnostic:FixItMessage {
				fileprivate let message:String = "remove the initializer from this variable declaration."
				fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_variable_initialization_unsupported")
			}
		}

		fileprivate struct ExtraneousVariableDeclaration:DiagnosticMessage {
			fileprivate let message:String = "extraneous variable declaration found. instance variables are not supported in this configuration."
			fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_extraneous_variable_declaration")
			fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
			fileprivate struct FixItDiagnosticRemoveMe:FixItMessage {
				fileprivate let message:String = "remove this instance variable."
				fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_extraneous_variable_declaration")
			}
			fileprivate struct FixItDiagnosticConvertToStatic:FixItMessage {
				fileprivate let message:String = "convert this instance variable to a static variable."
				fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_extraneous_variable_declaration_convert_to_static")
			}
		}

		fileprivate struct RAWCompareOverrideDiagnostics {
			fileprivate struct MissingStaticModifier:DiagnosticMessage {
				fileprivate let message:String = "expected to find a static modifier on the compare function override, but none was found."
				fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_compare_missing_static_modifier")
				fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
				fileprivate struct FixItDiagnostic:FixItMessage {
					fileprivate let message:String = "add static modifier to the function override."
					fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_compare_missing_static_modifier")
				}
			}

			fileprivate struct InvalidFunctionParameters:DiagnosticMessage {
				fileprivate let message:String = "this function is expected to have two named arguments `lhs_data` and `rhs_data` of type `UnsafeRawPointer`."
				fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_compare_invalid_function_parameters")
				fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
				fileprivate struct FixItDiagnostic:FixItMessage {
					fileprivate let message:String = "assign two function parameters: `lhs_data` and `rhs_data` of type `UnsafeRawPointer`."
					fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_compare_invalid_function_parameters")
				}
			}

			fileprivate struct InvalidReturnClause:DiagnosticMessage {
				fileprivate let message:String = "this function is expected to return an Int32 value."
				fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_compare_invalid_return_clause")
				fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
				fileprivate struct FixItDiagnostic:FixItMessage {
					fileprivate let message:String = "assign the return type to be `Int32`."
					fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_compare_invalid_return_clause")
				}
			}

			fileprivate struct AsyncEffectUnsupported:DiagnosticMessage {
				fileprivate let message:String = "async effect is not supported on this function. please remove the async effect from the function."
				fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_compare_async_effect_unsupported")
				fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
				fileprivate struct FixItDiagnostic:FixItMessage {
					fileprivate let message:String = "remove async effect from the function."
					fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_compare_async_effect_unsupported")
				}
			}

			fileprivate struct ThrowsEffectUnsupported:DiagnosticMessage {
				fileprivate let message:String = "throws effect is not supported on this function. please remove the throws effect from the function."
				fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_compare_throws_effect_unsupported")
				fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
				fileprivate struct FixItDiagnostic:FixItMessage {
					fileprivate let message:String = "remove throws effect from the function."
					fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_compare_throws_effect_unsupported")
				}
			}
		}
	}
}

public struct RAW_staticbuff_bytes_macro:MemberMacro, ExtensionMacro {
	private class NodeUsageParser:SyntaxVisitor {
		internal var numberOfBytes:Int? = nil
		override func visit(_ node:IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
			guard numberOfBytes == nil else {
				// if we have already found an integer literal, we should not find another one.
				return .skipChildren
			}
			numberOfBytes = Int(node.literal.text)!
			return .skipChildren
		}
	}

	public static func determineIfUsageCompliant(declaration:some SwiftSyntax.DeclGroupSyntax, node:SwiftSyntax.AttributeSyntax, context:some SwiftSyntaxMacros.MacroExpansionContext, addDiagnostics:Bool) -> (StructDeclSyntax, Bool, Int)? {
		guard let asStruct = AttachedMemberDiagnostics.validateAttachedMemberBasics(declaration:declaration, node:node, context:context, addDiagnostics:addDiagnostics) else {
			return nil
		}

		let nodeUsage = NodeUsageParser(viewMode: .sourceAccurate)
		nodeUsage.walk(node)
		guard let byteCount = nodeUsage.numberOfBytes else {
			if addDiagnostics {
				context.addDiagnostics(from:NodeUsageDiagnostics.ByteCountMissing(), node:node)
			}
			return nil
		}
		guard byteCount >= 0 else {
			if addDiagnostics {
				context.addDiagnostics(from:NodeUsageDiagnostics.InvalidByteCount(), node:node)
			}
			return nil
		}

		// find the RAW_compare function (as it may be overridden by the user). functions matching RAW_compare must be perfectly implemented else they will be rejected.
		var successfulRAWCompareOverride = false
		let compareFinder = FunctionFinder(viewMode:.sourceAccurate)
		compareFinder.validMatches.update(with:"RAW_compare")
		compareFinder.walk(asStruct)
		for foundFunc in compareFinder.funcDecl {
			// raw compare function overrides have the signature `static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32`
			
			// validate that the static modifier is present
			let staticFinder = StaticModifierFinder(viewMode:.sourceAccurate)
			staticFinder.walk(foundFunc)
			if staticFinder.foundStaticModifier == nil {
				if addDiagnostics == true {
					// define the syntax to offer as a replacement
					var foundFuncModify = foundFunc
					foundFuncModify.modifiers.append(DeclModifierSyntax(name:"static", trailingTrivia:.space))
					foundFuncModify.funcKeyword.leadingTrivia = ""
					// build diagnostic message
					let diagnosticMessage = Diagnostic(
						node:foundFunc,
						message:AttachedMemberDiagnostics.MemberContentDiagnostics.RAWCompareOverrideDiagnostics.MissingStaticModifier(),
						fixIts:[
							.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.RAWCompareOverrideDiagnostics.MissingStaticModifier.FixItDiagnostic(), oldNode:foundFunc, newNode:foundFuncModify)
						]
					)
					context.diagnose(diagnosticMessage)
				}
				return nil
			}

			// list the function parameters and validate that they are the expected types
			let fparams = FunctionParameterLister(viewMode:.sourceAccurate)
			fparams.walk(foundFunc)
			guard fparams.parameters.count == 2, fparams.parameters[0].firstName.text == "lhs_data", let idL = fparams.parameters[0].type.as(IdentifierTypeSyntax.self), let idR = fparams.parameters[1].type.as(IdentifierTypeSyntax.self), fparams.parameters[1].firstName.text == "rhs_data" && idL.name.text == "UnsafeRawPointer" && idR.name.text == "UnsafeRawPointer" else {
				if addDiagnostics == true {
					var foundFuncModify = foundFunc
					foundFuncModify.signature.parameterClause = FunctionParameterClauseSyntax(leftParen:.leftParenToken(), parameters:FunctionParameterListSyntax([FunctionParameterSyntax(firstName:"lhs_data", colon:":", type:IdentifierTypeSyntax(name:"UnsafeRawPointer", trailingTrivia:", ")), FunctionParameterSyntax(firstName:"rhs_data", colon:":", type:IdentifierTypeSyntax(name:"UnsafeRawPointer"))]), rightParen:.rightParenToken(), trailingTrivia:.space)
					let diagnosticMessage = Diagnostic(
						node:foundFunc.signature,
						message:AttachedMemberDiagnostics.MemberContentDiagnostics.RAWCompareOverrideDiagnostics.InvalidFunctionParameters(),
						fixIts:[
							.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.RAWCompareOverrideDiagnostics.InvalidFunctionParameters.FixItDiagnostic(), oldNode:foundFunc, newNode:foundFuncModify)
						]
					)
					context.diagnose(diagnosticMessage)
				}
				return nil
			}

			// validate the return clause
			let returnClauseFinder = ReturnClauseFinder(viewMode:.sourceAccurate)
			returnClauseFinder.walk(foundFunc)
			guard returnClauseFinder.returnClause?.type.as(IdentifierTypeSyntax.self)?.name.text == "Int32" else {
				if addDiagnostics == true {
					var foundFuncModify = foundFunc
					foundFuncModify.signature.returnClause = ReturnClauseSyntax(arrow:.arrowToken(), type:IdentifierTypeSyntax(leadingTrivia:.space, name:"Int32", trailingTrivia:.space))
					let diagnosticMessage = Diagnostic(
						node:foundFunc.signature,
						message:AttachedMemberDiagnostics.MemberContentDiagnostics.RAWCompareOverrideDiagnostics.InvalidReturnClause(),
						fixIts:[
							.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.RAWCompareOverrideDiagnostics.InvalidReturnClause.FixItDiagnostic(), oldNode:foundFunc, newNode:foundFuncModify)
						]
					)
					context.diagnose(diagnosticMessage)
				}
				return nil
			}

			// validate that the function does not have any effect specifiers
			let effectSpecifierSearch = FunctionEffectSpecifiersFinder(viewMode:.sourceAccurate)
			effectSpecifierSearch.walk(foundFunc)
			guard effectSpecifierSearch.effectSpecifier?.throwsClause?.throwsSpecifier == nil else {
				if addDiagnostics == true {
					var foundFuncModify = foundFunc
					foundFuncModify.signature.effectSpecifiers = nil
					let diagnosticMessage = Diagnostic(
						node:foundFunc.signature,
						message:AttachedMemberDiagnostics.MemberContentDiagnostics.RAWCompareOverrideDiagnostics.ThrowsEffectUnsupported(),
						fixIts:[
							.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.RAWCompareOverrideDiagnostics.ThrowsEffectUnsupported.FixItDiagnostic(), oldNode:foundFunc, newNode:foundFuncModify)
						]
					)
					context.diagnose(diagnosticMessage)
				}
				return nil
			}
			guard effectSpecifierSearch.effectSpecifier?.asyncSpecifier == nil else {
				if addDiagnostics == true {
					var foundFuncModify = foundFunc
					foundFuncModify.signature.effectSpecifiers = nil
					let diagnosticMessage = Diagnostic(
						node:foundFunc.signature,
						message:AttachedMemberDiagnostics.MemberContentDiagnostics.RAWCompareOverrideDiagnostics.AsyncEffectUnsupported(),
						fixIts:[
							.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.RAWCompareOverrideDiagnostics.AsyncEffectUnsupported.FixItDiagnostic(), oldNode:foundFunc, newNode:foundFuncModify)
						]
					)
					context.diagnose(diagnosticMessage)
				}
				return nil
			}
			// successful validation of the function override.
			successfulRAWCompareOverride = true
		}


		// throw a diagnostic on any variable declarations that are not computed
		let varScanner = VariableDeclLister(viewMode:.sourceAccurate)
		varScanner.walk(asStruct)
		for curVar in varScanner.varDecls {
			let abLister = AccessorBlockLister(viewMode:.sourceAccurate)
			abLister.walk(curVar)
			let staticFinder = StaticModifierFinder(viewMode:.sourceAccurate)
			staticFinder.walk(curVar)

			guard abLister.accessorBlocks.count > 0 || staticFinder.foundStaticModifier != nil else {
				if addDiagnostics == true {
					var curVarModify = curVar
					curVarModify.modifiers.append(DeclModifierSyntax(name:"static", trailingTrivia:.space))
					curVarModify.bindingSpecifier.leadingTrivia = .space
					let diagnose = Diagnostic(
						node:curVar,
						message:AttachedMemberDiagnostics.MemberContentDiagnostics.ExtraneousVariableDeclaration(),
						fixIts:[
							.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.ExtraneousVariableDeclaration.FixItDiagnosticRemoveMe(), oldNode:curVar, newNode:DeclSyntax("")),
							.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.ExtraneousVariableDeclaration.FixItDiagnosticConvertToStatic(), oldNode:curVar, newNode:curVarModify)
						]
					)
					context.diagnose(diagnose)
					return nil
				}
				return nil
			}
		}

		return (asStruct, successfulRAWCompareOverride, byteCount)
	}

	public static func expansion(of node:SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		guard Self.determineIfUsageCompliant(declaration:declaration, node:node, context:context, addDiagnostics:false) != nil else {
			return []
		}

		return [try ExtensionDeclSyntax("""
			extension \(type):RAW_staticbuff {}
		""")]
	}

	public static func expansion(of node:SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard let (asStruct, _, byteCount) = Self.determineIfUsageCompliant(declaration:declaration, node:node, context:context, addDiagnostics:true) else {
			return []
		}

		var declString = [DeclSyntax]()
		let varName = context.makeUniqueName("RAW_staticbuff_private_store")
		// assemble the primary extension declaration.
		declString.append(
			DeclSyntax("""
			/// \(raw:byteCount)x UInt8 literal type (identical to ``RAW_fixed_type``)
			\(raw:asStruct.modifiers) typealias RAW_staticbuff_storetype = \(generateUnsignedByteTypeExpression(byteCount:UInt16(byteCount)))
		"""))
		declString.append(
			DeclSyntax("""
			private var \(varName):RAW_staticbuff_storetype
			""")
		)

		declString.append(DeclSyntax("""
			/// initialize the static buffer from its raw representation store type. behavior is undefined if the raw representation is shorter than the assumed size of the static buffer.
			\(asStruct.modifiers) init(RAW_staticbuff storetype:consuming RAW_staticbuff_storetype) {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "static buffer type stride mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "static buffer type alignment mismatch. this is a misuse of the macro")
				#endif
				\(varName) = storetype
			}
		"""))

		declString.append(DeclSyntax("""
			/// borrow the raw representation of the static buffer.
			\(asStruct.modifiers) consuming func RAW_staticbuff() -> RAW_staticbuff_storetype {
				return \(varName)
			}
		"""))

		declString.append(DeclSyntax("""
			/// compare two instances of the same type.
			\(asStruct.modifiers) static func RAW_staticbuff_zeroed() -> RAW_staticbuff_storetype {
				return \(raw:generateZeroLiteralExpression(byteCount:UInt16(byteCount)))
			}
		"""))

		// apply the default implementations for the protocol conformance
		declString.append(DeclSyntax("""
			/// initialize the static buffer from a pointer to its raw representation store type. behavior is undefined if the raw representation is shorter than the assumed size of the static buffer.
			\(asStruct.modifiers) init(RAW_staticbuff ptr:UnsafeRawPointer) {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "static buffer type stride mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "static buffer type alignment mismatch. this is a misuse of the macro")
				#endif
				self = ptr.load(as:Self.self)
			}
		"""))

		declString.append(DeclSyntax("""
			\(asStruct.modifiers) borrowing func RAW_encode(count: inout size_t) {
				count += MemoryLayout<RAW_staticbuff_storetype>.size
			}
		"""))
		declString.append(DeclSyntax("""
			@discardableResult \(asStruct.modifiers) borrowing func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
				withUnsafePointer(to:self) { buff in
					_ = RAW_memcpy(dest, buff, MemoryLayout<RAW_staticbuff_storetype>.size)!
				}
				return dest.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
			}
		"""))
		declString.append(DeclSyntax("""
			\(asStruct.modifiers) borrowing func RAW_access<R, E>(_ body: (UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
				return try withUnsafePointer(to:self) { (buff:UnsafePointer<Self>) throws(E) -> R in
					let asBuffer = UnsafeBufferPointer<UInt8>(start:UnsafeRawPointer(buff).assumingMemoryBound(to:UInt8.self), count:MemoryLayout<RAW_staticbuff_storetype>.size)
					return try body(asBuffer)
				}
			}
		"""))
		declString.append(DeclSyntax("""
			\(asStruct.modifiers) borrowing func RAW_access_staticbuff<R, E>(_ body:(UnsafeRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
				return try withUnsafePointer(to:self) { (buff:UnsafePointer<Self>) throws(E) -> R in
					return try body(buff)
				}
			}
		"""))
		declString.append(DeclSyntax("""
			\(asStruct.modifiers) mutating func RAW_access_staticbuff_mutating<R, E>(_ body:(UnsafeMutableRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
				return try withUnsafeMutablePointer(to:&self) { (buff:UnsafeMutablePointer<Self>) throws(E) -> R in
					return try body(UnsafeMutableRawPointer(buff))
				}
			}
		"""))
		
		return declString
	}
}