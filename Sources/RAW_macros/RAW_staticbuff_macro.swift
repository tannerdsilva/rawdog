// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

extension Array where Element == TokenSyntax {
	// returns a string representation of the array of tokens.
	fileprivate func toTypeSyntaxProtocol() -> TypeSyntaxProtocol? {
		guard self.count > 0 else {
			return nil
		}
		guard count > 1 else {
			return IdentifierTypeSyntax(name:self[0])
		}
		var curMT:MemberTypeSyntax? = nil
		let idType = IdentifierTypeSyntax(name:self[0])
		var i = 1
		repeat {
			defer {
				i += 1
			}
			if curMT == nil {
				let newMT = MemberTypeSyntax(baseType:idType, name:self[i])
				curMT = newMT
			} else {
				curMT = MemberTypeSyntax(baseType:curMT!, name:self[i])
			}
		} while i < count
		return curMT
	}
}

extension AttachedMemberDiagnostics.MemberContentDiagnostics.TypeAnnotationFinder.TypeAnnotationType {
	// returns the type syntax protocol for the type annotation type.
	fileprivate func toTypeSyntaxProtocol() -> TypeSyntaxProtocol? {
		switch self {
			case .memberType(let memberType):
				return memberType
			case .identifierType(let identifierType):
				return identifierType
			case .tupleType(let tupleType):
				return tupleType
		}
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
		fileprivate final class TypeAnnotationFinder:SyntaxVisitor {
			fileprivate enum TypeAnnotationType {
				case memberType(MemberTypeSyntax)
				case identifierType(IdentifierTypeSyntax)
				case tupleType(TupleTypeSyntax)
			}
			private final class TypeAnnotationMixedUseIdentifier:SyntaxVisitor {
				fileprivate var foundTypeAnnotationType:TypeAnnotationType? = nil
				override func visit(_ node:IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
					switch foundTypeAnnotationType {
						case nil:
							foundTypeAnnotationType = .identifierType(node)
							return .skipChildren
						case .some:
							return .skipChildren
					}
				}
				override func visit(_ node:TupleTypeSyntax) -> SyntaxVisitorContinueKind {
					switch foundTypeAnnotationType {
						case nil:
							foundTypeAnnotationType = .tupleType(node)
							return .skipChildren
						case .some:
							return .skipChildren
					}
				}
				override func visit(_ node:MemberTypeSyntax) -> SyntaxVisitorContinueKind {
					switch foundTypeAnnotationType {
						case nil:
							foundTypeAnnotationType = .memberType(node)
							return .skipChildren
						case .some:
							return .skipChildren
					}
				}
			}
			var foundTypeAnnotation:TypeAnnotationType? = nil
			override func visit(_ node:TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
				let mixedUseIdentifier = TypeAnnotationMixedUseIdentifier(viewMode:.sourceAccurate)
				mixedUseIdentifier.walk(node)
				switch (foundTypeAnnotation, mixedUseIdentifier.foundTypeAnnotationType) {
					case (nil, let typeAnnotationType):
						foundTypeAnnotation = typeAnnotationType
						return .skipChildren
					case (_, _):
						return .skipChildren
				}
			}
		}

		fileprivate struct VariableNameNotFound:Swift.Error, DiagnosticMessage {
			fileprivate let message:String = "expected to find a variable name, but none was found."
			fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_variable_name_not_found")
			fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		}

		fileprivate struct VariableInitializationUnsupported:DiagnosticMessage {
			fileprivate let message:String = "variable initialization not supported. please modify this variable expression to not have an initializer."
			fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_variable_initialization_unsupported")
			fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
			fileprivate struct FixItDiagnostic:FixItMessage {
				fileprivate let message:String = "remove the initializer from this variable declaration."
				fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_variable_initialization_unsupported")
			}
		}

		fileprivate struct VariableTypeMissing:DiagnosticMessage {
			fileprivate let message:String
			fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_variable_type_missing")
			fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
			fileprivate init(expectedType:TypeSyntaxProtocol) {
				self.message = "expected to find a variable type of \(expectedType), but none was found."
			}
			fileprivate struct FixItDiagnosticSuggestExpectedType:FixItMessage {
				fileprivate let message:String
				fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_variable_type_missing")
				fileprivate init(expectedType:TypeSyntaxProtocol) {
					self.message = "add the expected identifier type \(expectedType)."
				}
			}
		}
		fileprivate struct VariableTypeInvalidExplicit:DiagnosticMessage {
			fileprivate let message:String
			fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_variable_type_invalid")
			fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
			fileprivate init(expectedType:TypeSyntaxProtocol, foundType:TypeSyntaxProtocol) {
				self.message = "expected to find a variable type of \(expectedType), but instead found \(foundType)."
			}
			fileprivate struct FixItDiagnosticSuggestExpectedType:FixItMessage {
				fileprivate let message:String
				fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_variable_type_invalid")
				fileprivate init(expectedType:TypeSyntaxProtocol) {
					self.message = "replace variable type with the expected type \(expectedType)."
				}
			}
		}
		fileprivate struct VariableTypeTupleNotAllowed:DiagnosticMessage {
			fileprivate let message:String = "tuple typed instance variables are not allowed. please use a single identifier pattern for the variable name."
			fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_variable_type_tuple_not_allowed")
			fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
			fileprivate struct FixItDiagnosticSuggestExpectedType:FixItMessage {
				fileprivate let message:String
				fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_variable_type_tuple_not_allowed")
				fileprivate init(expectedType:TypeSyntaxProtocol) {
					self.message = "replace variable type with the expected type \(expectedType)."
				}
			}
		}

		fileprivate struct ExtraneousVariableDeclaration:DiagnosticMessage {
			fileprivate let message:String
			fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_extraneous_variable_declaration")
			fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
			fileprivate init(expectedNumberOfVariables:Int) {
				self.message = "extraneous variable declaration found. expected to find \(expectedNumberOfVariables) instance variables."
			}
			fileprivate struct FixItDiagnosticRemoveMe:FixItMessage {
				fileprivate let message:String = "remove this instance variable."
				fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_extraneous_variable_declaration")
			}
			fileprivate struct FixItDiagnosticConvertToStatic:FixItMessage {
				fileprivate let message:String = "convert this instance variable to a static variable."
				fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_extraneous_variable_declaration_convert_to_static")
			}
		}

		fileprivate struct VariableNotImplemented:Swift.Error, DiagnosticMessage {
			fileprivate let message:String = "this variable is not implemented in the attached body. please implement this variable in the body to resolve this error."
			fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_variable_not_implemented")
			fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
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

fileprivate struct NodeUsageDiagnostics {
	fileprivate final class MemberTypesToTokens:SyntaxVisitor {
		fileprivate var foundTypes:[TokenSyntax] = []
		override func visit(_ node:MemberTypeSyntax) -> SyntaxVisitorContinueKind {
			foundTypes.insert(node.name, at:0)
			return .visitChildren
		}
		override func visit(_ node:IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
			foundTypes.insert(node.name, at:0)
			return .skipChildren
		}
	}

	fileprivate struct ConvertToValidTypeReference:DiagnosticMessage {
		fileprivate let message:String
		fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_convert_to_valid_type_reference")
		fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		fileprivate init(foundType:TokenSyntax) {
			self.message = "expected to find a valid type reference, but found '\(foundType.text)' instead. versions of swift 6 and prior will compile and work as expected, but starting in swift 6.1, this syntax will be rejected. please update this syntax to use a valid type reference."
		}
		fileprivate struct FixItDiagnostic:FixItMessage {
			fileprivate let message:String
			fileprivate let fixItID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_fix_convert_to_valid_type_reference")
			fileprivate init(foundType:TokenSyntax) {
				self.message = "append '.self' syntax after '\(foundType.text)'."
			}
		}
	}

	fileprivate struct IncomplateTypeDeclaration:Swift.Error, DiagnosticMessage {
		fileprivate let message:String
		fileprivate let diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_incomplete_type_declaration")
		fileprivate let severity:SwiftDiagnostics.DiagnosticSeverity = .error
		fileprivate init() {
			self.message = "this type declaration is missing the base name for the type. please write a complete type referece to resolve this error."
		}
	}

	fileprivate final class ConcatTypeLister:SyntaxVisitor {
		private let context:SwiftSyntaxMacros.MacroExpansionContext
		private var foundLabeledExprList:LabeledExprListSyntax? = nil
		fileprivate var foundTypes:[(ExprSyntax, [TokenSyntax])] = []
		private let addDiagnostics:Bool
		fileprivate var valid:Bool = true
		fileprivate init(context:SwiftSyntaxMacros.MacroExpansionContext, addDiagnostics:Bool) {
			self.context = context
			self.addDiagnostics = addDiagnostics
			super.init(viewMode:.sourceAccurate)
		}
		override func visit(_ node:DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
			if addDiagnostics == true {
				let diagnosticMessage = Diagnostic(
					node:node,
					message:NodeUsageDiagnostics.ConvertToValidTypeReference(foundType:node.baseName),
					fixIts:[
						.replace(message:NodeUsageDiagnostics.ConvertToValidTypeReference.FixItDiagnostic(foundType:node.baseName), oldNode:node, newNode:DeclSyntax("\(node.baseName).self"))
					]
				)
				context.diagnose(diagnosticMessage)
			}
			valid = false
			return .skipChildren
		}
		override func visit(_ node:LabeledExprListSyntax) -> SyntaxVisitorContinueKind {
			switch foundLabeledExprList {
				case nil:
					foundLabeledExprList = node
					return .visitChildren
				case .some:
					return .skipChildren
			}
		}
		private final class ValidDeclReferenceExprSyntaxLister:SyntaxVisitor {
			var foundDeclReferenceExpr:Array<DeclReferenceExprSyntax> = []
			override func visit(_ node:DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
				foundDeclReferenceExpr.append(node)
				return .visitChildren
			}
		}
		override func visit(_ node:MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
			guard node.base != nil else {
				valid = false
				if addDiagnostics == true {
					context.addDiagnostics(from:NodeUsageDiagnostics.IncomplateTypeDeclaration(), node:node)
				}
				return .skipChildren
			}
			let validDeclReferenceExprLister = ValidDeclReferenceExprSyntaxLister(viewMode:.sourceAccurate)
			validDeclReferenceExprLister.walk(node.base!)
			guard validDeclReferenceExprLister.foundDeclReferenceExpr.count >= 1 else {
				valid = false
				if addDiagnostics == true {
					context.addDiagnostics(from:NodeUsageDiagnostics.IncomplateTypeDeclaration(), node:node)
				}
				return .skipChildren
			}

			let foundDeclReferenceExpr = validDeclReferenceExprLister.foundDeclReferenceExpr
			foundTypes.append((node.base!, foundDeclReferenceExpr.map { $0.baseName }))
			return .skipChildren
		}
	}
}

public struct RAW_staticbuff_concat_macro:MemberMacro, ExtensionMacro {

	// added when the user invokes the concat macro but doesn't specify any types.
	public struct MissingConcatTypes:Swift.Error, DiagnosticMessage {
		public var message:String = "expected to find at least one type token for the concat macro."
		public var diagnosticID:SwiftDiagnostics.MessageID = MessageID(domain:"RAW_macros", id:"staticbuff_concat_missing_types")
		public var severity: SwiftDiagnostics.DiagnosticSeverity = .error
	}

	private final class InitializationFinder:SyntaxVisitor {
		var initializers: [InitializerClauseSyntax] = [InitializerClauseSyntax]()
		override func visit(_ node:InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
			initializers.append(node)
			return .skipChildren
		}
	}

	private final class VariableTypeAnnotationFinder:SyntaxVisitor {
		var typeAnnotation:IdentifierTypeSyntax? = nil
		override func visit(_ node:TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
			guard typeAnnotation == nil else {
				return .skipChildren
			}
			let idScanner = IdTypeLister(viewMode:.sourceAccurate)
			idScanner.walk(node)
			typeAnnotation = idScanner.listedIDTypes.first
			return .skipChildren
		}
	}

	private final class VariableNameFinder:SyntaxVisitor {
		private final class IdTypeLister:SyntaxVisitor {
			var listedIDTypes:[IdentifierPatternSyntax] = []
			override func visit(_ node:IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
				listedIDTypes.append(node)
				return .skipChildren
			}
		}
		var name:IdentifierPatternSyntax? = nil
		override func visit(_ node:PatternBindingSyntax) -> SyntaxVisitorContinueKind {
			guard name == nil else {
				return .skipChildren
			}
			let idScanner = IdTypeLister(viewMode:.sourceAccurate)
			idScanner.walk(node)
			guard idScanner.listedIDTypes.count == 1 else {
				return .skipChildren
			}
			name = idScanner.listedIDTypes.first!
			return .skipChildren
		}
	}

	fileprivate static func determineIfUsageCompliant(declaration:some SwiftSyntax.DeclGroupSyntax, node:SwiftSyntax.AttributeSyntax, context:some SwiftSyntaxMacros.MacroExpansionContext, addDiagnostics:Bool) -> (StructDeclSyntax, [[TokenSyntax]], [(name:IdentifierPatternSyntax, type:[TokenSyntax])], Bool)? {
		guard let asStruct = AttachedMemberDiagnostics.validateAttachedMemberBasics(declaration:declaration, node:node, context:context, addDiagnostics:addDiagnostics) else {
			return nil
		}

		let concatLister = NodeUsageDiagnostics.ConcatTypeLister(context:context, addDiagnostics:addDiagnostics)
		concatLister.walk(node)
		guard concatLister.valid == true else {
			return nil
		}

		// determine how the macro was used. there should be some number of type tokens in the macro usage.
		let typeTokens = concatLister.foundTypes
		guard typeTokens.count > 0 else {
			if addDiagnostics == true {
				context.addDiagnostics(from:MissingConcatTypes(), node:node)
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

		let varScanner = VariableDeclLister(viewMode:.sourceAccurate)
		varScanner.walk(asStruct)
		var typeTokensRemaining = typeTokens
		var assembleVariableNamesAndTypes = [(name:IdentifierPatternSyntax, type:[TokenSyntax])]()
		var buildAllTypeTokens = [[TokenSyntax]]()
		varLoop: for curVar in varScanner.varDecls {
			// variables with accessor blocks are allowed and do not fall into the validation logic
			let abLister = AccessorBlockLister(viewMode:.sourceAccurate)
			abLister.walk(curVar)
			guard abLister.accessorBlocks.count == 0 else {
				continue varLoop
			}
			// static variables are allowed and do not fall into the validation logic, since these are global variables and not anything affecting the memory layout of an instance of the struct.
			let staticFinder = StaticModifierFinder(viewMode:.sourceAccurate)
			staticFinder.walk(curVar)
			guard staticFinder.foundStaticModifier == nil else {
				continue varLoop
			}

			// at this point the varaible decl should be flagged if it is overflowing from the number of expected types.
			if typeTokensRemaining.count == 0 {
				// if there are no type tokens remaining, then this variable is not expected to be here.
				if addDiagnostics == true {
					var modifiedVar = curVar
					modifiedVar.modifiers.append(DeclModifierSyntax(name:"static", trailingTrivia:.space))
					modifiedVar.bindingSpecifier.leadingTrivia = ""
					let diagnosticMessage = Diagnostic(
						node:curVar,
						message:AttachedMemberDiagnostics.MemberContentDiagnostics.ExtraneousVariableDeclaration(expectedNumberOfVariables:typeTokens.count),
						fixIts:[
							.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.ExtraneousVariableDeclaration.FixItDiagnosticRemoveMe(), oldNode:curVar, newNode:DeclSyntax("")),
							.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.ExtraneousVariableDeclaration.FixItDiagnosticConvertToStatic(), oldNode:curVar, newNode:modifiedVar)
						]
					)
					context.diagnose(diagnosticMessage)
				}
				return nil
			}

			// any logic beyond this point assumes the responsibility of removing the variable decl the typeTokensRemaining list.
			let expectedType = typeTokensRemaining.first!

			// validate that no tuple patterns are used in the declaration of this variable.
			let typeFinder = AttachedMemberDiagnostics.MemberContentDiagnostics.TypeAnnotationFinder(viewMode:.sourceAccurate)
			typeFinder.walk(curVar.bindings)
			switch typeFinder.foundTypeAnnotation {
				case .memberType(let memberType):
					guard let correspondingType = expectedType.1.toTypeSyntaxProtocol() else {
						typeTokensRemaining.remove(at:0)
						return nil
					}
					guard let expectedType = correspondingType.as(MemberTypeSyntax.self) else {
						if let expectedType = correspondingType.as(IdentifierTypeSyntax.self) {
							// suggest the user change their variable type to the expected type.
							if addDiagnostics == true {
								var modifyVar = curVar
								var firstBinding = modifyVar.bindings.first!
								firstBinding.typeAnnotation = TypeAnnotationSyntax(colon:.colonToken(), type:expectedType)
								modifyVar.bindings = [firstBinding]
								let diagnosticMessage = Diagnostic(
									node:curVar.bindings,
									message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit(expectedType:expectedType, foundType:memberType),
									fixIts:[
										.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit.FixItDiagnosticSuggestExpectedType(expectedType:expectedType), oldNode:curVar, newNode:modifyVar)
									]
								)
								context.diagnose(diagnosticMessage)
							}
							typeTokensRemaining.remove(at:0)
							return nil
						} else {
							typeTokensRemaining.remove(at:0)
							return nil
						}
					}
					// convert the configured (and expected) member type into a token list. validate that content is found.
					let memberTypesToTokens = NodeUsageDiagnostics.MemberTypesToTokens(viewMode:.sourceAccurate)
					memberTypesToTokens.walk(expectedType)
					guard memberTypesToTokens.foundTypes.count >= 1 else {
						// this is an internal error with nothing we can suggest to the user.
						typeTokensRemaining.remove(at:0)
						return nil
					}
					let configuredTypeExpected = memberTypesToTokens.foundTypes

					// now convert the found member type into a token list.
					let memberTypeTokens = NodeUsageDiagnostics.MemberTypesToTokens(viewMode:.sourceAccurate)
					memberTypeTokens.walk(memberType)
					guard memberTypeTokens.foundTypes.count >= 1 else {
						if addDiagnostics == true {
							let diagnosticMessage = Diagnostic(
								node:memberType.name,
								message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit(expectedType:expectedType, foundType:memberType),
								fixIts:[
									.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit.FixItDiagnosticSuggestExpectedType(expectedType:expectedType), oldNode:curVar, newNode:curVar)
								]
							)
							context.diagnose(diagnosticMessage)
						}
						typeTokensRemaining.remove(at:0)
						return nil
					}
					let foundMemberTypeTokens = memberTypeTokens.foundTypes

					// validate that the configured type matches the expected type.
					guard configuredTypeExpected.count == foundMemberTypeTokens.count else {
						if addDiagnostics == true {
							var modifyVar = curVar
							var firstBinding = modifyVar.bindings.first!
							firstBinding.typeAnnotation = TypeAnnotationSyntax(colon:.colonToken(), type:expectedType)
							modifyVar.bindings = [firstBinding]
							let diagnosticMessage = Diagnostic(
								node:curVar.bindings,
								message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit(expectedType:expectedType, foundType:memberType),
								fixIts:[
									.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit.FixItDiagnosticSuggestExpectedType(expectedType:expectedType), oldNode:curVar, newNode:modifyVar)
								]
							)
							context.diagnose(diagnosticMessage)
						}
						typeTokensRemaining.remove(at:0)
						return nil
					}
					// validate a match of each index of the configured type and the found member type.
					for (index, configuredTypeToken) in configuredTypeExpected.enumerated() {
						guard configuredTypeToken.text == foundMemberTypeTokens[index].text else {
							if addDiagnostics == true {
								var modifyVar = curVar
								var firstBinding = modifyVar.bindings.first!
								firstBinding.typeAnnotation = TypeAnnotationSyntax(colon:.colonToken(), type:expectedType)
								modifyVar.bindings = [firstBinding]
								let diagnosticMessage = Diagnostic(
									node:curVar.bindings,
									message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit(expectedType:expectedType, foundType:memberType),
									fixIts:[
										.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit.FixItDiagnosticSuggestExpectedType(expectedType:expectedType), oldNode:curVar, newNode:modifyVar)
									]
								)
								context.diagnose(diagnosticMessage)
							}
							typeTokensRemaining.remove(at:0)
							return nil
						}
					}
					break;
				case .identifierType(let idType):
					guard let correspondingType = expectedType.1.toTypeSyntaxProtocol() else {
						typeTokensRemaining.remove(at:0)
						return nil
					}
					guard let expectedType = correspondingType.as(IdentifierTypeSyntax.self) else {
						if let expectedType = correspondingType.as(MemberTypeSyntax.self) {
							// suggest the user change their variable type to the expected type.
							if addDiagnostics == true {
								var modifyVar = curVar
								var firstBinding = modifyVar.bindings.first!
								firstBinding.typeAnnotation = TypeAnnotationSyntax(colon:.colonToken(), type:expectedType)
								modifyVar.bindings = [firstBinding]
								let diagnosticMessage = Diagnostic(
									node:curVar.bindings,
									message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit(expectedType:expectedType, foundType:idType),
									fixIts:[
										.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit.FixItDiagnosticSuggestExpectedType(expectedType:expectedType), oldNode:curVar, newNode:modifyVar)
									]
								)
								context.diagnose(diagnosticMessage)
							}
							typeTokensRemaining.remove(at:0)
							return nil
						} else {
							typeTokensRemaining.remove(at:0)
							return nil
						}
					}
					// validate that this type is the expected type
					guard idType.name.text == expectedType.name.text else {
						if addDiagnostics == true {
							var modifyVar = curVar
							var firstBinding = modifyVar.bindings.first
							firstBinding?.typeAnnotation = TypeAnnotationSyntax(colon:.colonToken(), type:expectedType)
							modifyVar.bindings = [firstBinding!]
							let diagnosticMessage = Diagnostic(
								node:curVar.bindings,
								message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit(expectedType:expectedType, foundType:idType),
								fixIts:[
									.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeInvalidExplicit.FixItDiagnosticSuggestExpectedType(expectedType:expectedType), oldNode:curVar, newNode:modifyVar)
								]
							)
							context.diagnose(diagnosticMessage)
						}
						typeTokensRemaining.remove(at:0)
						return nil
					}
					break
				case .tupleType(_):
					if addDiagnostics == true {
						guard let expectedType = expectedType.1.toTypeSyntaxProtocol() else {
							return nil
						}
						var modifyVar = curVar
						var firstBinding = modifyVar.bindings.first!
						firstBinding.typeAnnotation = TypeAnnotationSyntax(colon:.colonToken(), type:expectedType)
						modifyVar.bindings = [firstBinding]
						let diagnosticMessage = Diagnostic(
							node:curVar.bindings,
							message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeTupleNotAllowed(),
							fixIts:[
								.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeTupleNotAllowed.FixItDiagnosticSuggestExpectedType(expectedType:expectedType), oldNode:curVar, newNode:modifyVar)
							]
						)
						context.diagnose(diagnosticMessage)
					}
					typeTokensRemaining.remove(at:0)
					return nil
				case nil:
					if addDiagnostics == true {
						guard let expectedType = expectedType.1.toTypeSyntaxProtocol() else {
							typeTokensRemaining.remove(at:0)
							return nil
						}
						var modifyVar = curVar
						var firstBinding = modifyVar.bindings.first!
						firstBinding.typeAnnotation = TypeAnnotationSyntax(colon:.colonToken(), type:expectedType)
						modifyVar.bindings = [firstBinding]
						let diagnosticMessage = Diagnostic(
							node:curVar.bindings,
							message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeMissing(expectedType:expectedType),
							fixIts:[
								.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableTypeMissing.FixItDiagnosticSuggestExpectedType(expectedType:expectedType), oldNode:curVar, newNode:modifyVar)
							]
						)
						context.diagnose(diagnosticMessage)
					}
					typeTokensRemaining.remove(at:0)
					return nil
			}

			// validate that the variable is not initialized.
			let initFinder = InitializationFinder(viewMode:.sourceAccurate)
			initFinder.walk(curVar)
			guard initFinder.initializers.count == 0 else {
				if addDiagnostics == true {
					var modifyVar = curVar
					var firstBinding = modifyVar.bindings.first!
					firstBinding.initializer = nil
					modifyVar.bindings = [firstBinding]
					let diagnosticMessage = Diagnostic(
						node:curVar.bindings,
						message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableInitializationUnsupported(),
						fixIts:[
							.replace(message:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableInitializationUnsupported.FixItDiagnostic(), oldNode:curVar, newNode:modifyVar)
						]
					)
					context.diagnose(diagnosticMessage)
				}
				typeTokensRemaining.remove(at:0)
				return nil
			}

			// find the variable name
			let varNameFinder = VariableNameFinder(viewMode:.sourceAccurate)
			varNameFinder.walk(curVar)
			guard varNameFinder.name != nil else {
				if addDiagnostics == true {
					context.addDiagnostics(from:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableNameNotFound(), node:curVar)
				}
				typeTokensRemaining.remove(at:0)
				return nil
			}
			assembleVariableNamesAndTypes.append((name:varNameFinder.name!, type:expectedType.1))
			buildAllTypeTokens.append(expectedType.1)
			typeTokensRemaining.remove(at:0)
		}

		// flag leftover type tokens (in the macro syntax) as unimplemented if they exist.
		guard typeTokensRemaining.count == 0 else {
			for token in typeTokensRemaining {
				if addDiagnostics == true {
					context.addDiagnostics(from:AttachedMemberDiagnostics.MemberContentDiagnostics.VariableNotImplemented(), node:token.0)
				}
			}
			return nil
		}
		
		return (asStruct, buildAllTypeTokens, assembleVariableNamesAndTypes, successfulRAWCompareOverride)
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		guard Self.determineIfUsageCompliant(declaration:declaration, node:node, context:context, addDiagnostics:true) != nil else {
			return []
		}

		return [try ExtensionDeclSyntax("""
			// extension of \(type) to provide the RAW_staticbuff protocol conformance.
			extension \(type):RAW_staticbuff {}
		""")]
	}

	public static func expansion(of node:SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, conformingTo protocols:[TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		
		guard let (asStruct, typeTokens, varNamesAndTypes, isCompareOverridden) = Self.determineIfUsageCompliant(declaration:declaration, node:node, context:context, addDiagnostics:false) else {
			return []
		}

		var buildDecls = [DeclSyntax]()

		if isCompareOverridden == false {
			// write the custom compare function for this type.
			var buildCompare = [String]()
			for (_, curType) in varNamesAndTypes {
				buildCompare.append("""
					compare_result = \(curType.map({ $0.text }).joined(separator:".")).RAW_compare(lhs_data_seeking:&lhs_seeker, rhs_data_seeking:&rhs_seeker)
					guard compare_result == 0 else {
						return compare_result
					}
				""")
			}
			buildDecls.append(DeclSyntax("""
				/// compare two instances of the same type.
				\(raw:asStruct.modifiers) static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
					#if DEBUG
					assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
					assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "static buffer type stride mismatch. this is a misuse of the macro")
					assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "static buffer type alignment mismatch. this is a misuse of the macro")
					#endif
					var compare_result:Int32
					var lhs_seeker = lhs_data
					var rhs_seeker = rhs_data

					\(raw:buildCompare.joined(separator: "\n"))

					return compare_result
				}
			"""))
		}
		buildDecls.append(DeclSyntax("""
			\(raw:asStruct.modifiers) init(RAW_staticbuff storetype:consuming RAW_staticbuff_storetype) {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "static buffer type stride mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "static buffer type alignment mismatch. this is a misuse of the macro")
				#endif
				self = withUnsafePointer(to:&storetype) { ptr in
					return UnsafeRawPointer(ptr).load(as:Self.self)
				}
			}
		"""))

		buildDecls.append(DeclSyntax("""
			\(raw:asStruct.modifiers) consuming func RAW_staticbuff() -> RAW_staticbuff_storetype {
				return withUnsafePointer(to:&self) { ptr in
					return UnsafeRawPointer(ptr).load(as:RAW_staticbuff_storetype.self)
				}
			}
		"""))

		// assemble the primary extension declaration.
		var buildStoreTypes:[String] = []
		var buildZeroedCommand:[String] = []
		for token in typeTokens {
			buildStoreTypes.append("\(token.map({ $0.text }).joined(separator:".")).RAW_staticbuff_storetype")
			buildZeroedCommand.append("\(token.map({ $0.text }).joined(separator:".")).RAW_staticbuff_zeroed()")
		}
		buildDecls.append(
			DeclSyntax("""
				\(raw:asStruct.modifiers) typealias RAW_staticbuff_storetype = (\(raw:buildStoreTypes.joined(separator: ", ")))
			"""))
		buildDecls.append(
			DeclSyntax("""
				/// returns a zeroed instance of the RAW_staticbuff type.
				\(raw:asStruct.modifiers) static func RAW_staticbuff_zeroed() -> RAW_staticbuff_storetype {
					return (\(raw:buildZeroedCommand.joined(separator: ", ")))
				}
			"""))

		// apply the default implementations for the protocol conformance
		buildDecls.append(DeclSyntax("""
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
		buildDecls.append(DeclSyntax("""
			\(asStruct.modifiers) borrowing func RAW_encode(count: inout size_t) {
				count += MemoryLayout<RAW_staticbuff_storetype>.size
			}
		"""))
		buildDecls.append(DeclSyntax("""
			@discardableResult \(asStruct.modifiers) borrowing func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
				withUnsafePointer(to:self) { buff in
					_ = RAW_memcpy(dest, buff, MemoryLayout<RAW_staticbuff_storetype>.size)!
				}
				return dest.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(asStruct.modifiers) borrowing func RAW_access<R, E>(_ body: (UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
				return try withUnsafePointer(to:self) { (buff:UnsafePointer<Self>) throws(E) -> R in
					let asBuffer = UnsafeBufferPointer<UInt8>(start:UnsafeRawPointer(buff).assumingMemoryBound(to:UInt8.self), count:MemoryLayout<RAW_staticbuff_storetype>.size)
					return try body(asBuffer)
				}
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(asStruct.modifiers) borrowing func RAW_access_staticbuff<R, E>(_ body:(UnsafeRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
				return try withUnsafePointer(to:self) { (buff:UnsafePointer<Self>) throws(E) -> R in
					return try body(buff)
				}
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(asStruct.modifiers) mutating func RAW_access_staticbuff_mutating<R, E>(_ body:(UnsafeMutableRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
				return try withUnsafeMutablePointer(to:&self) { (buff:UnsafeMutablePointer<Self>) throws(E) -> R in
					return try body(UnsafeMutableRawPointer(buff))
				}
			}
		"""))
		return buildDecls
	}
}
