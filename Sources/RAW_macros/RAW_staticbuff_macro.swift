import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

fileprivate let domain = "RAW_staticbuff_macro"

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:domain)
#endif

/// thrown when a stored variable gets attached to a static buffer macro.
public struct StoredVariablesUnsupported:Swift.Error, DiagnosticMessage {
	public var message:String { "stored variables not supported in this mode. please add an accessor block or move this variable to a standalone extension." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_stored_variables_unsupported")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

/// thrown when a user attempts to use a tuple pattern binding for variables instead of a single identifier pattern.
public struct TuplePatternBindingsUnsupported:Swift.Error, DiagnosticMessage {
	public var message:String { "tuple pattern bindings not supported in this mode. please modify this variable expression to only use a single IdentifierPattern for its name" }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_tuple_pattern_bindings_unsupported")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

public struct VariableInitializationUnsupported:Swift.Error, DiagnosticMessage {
	public var message:String { "variable initialization not supported in this mode. please modify this variable expression to not have an initializer." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_variable_initialization_unsupported")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

public struct UnexpectedVariableType:Swift.Error, DiagnosticMessage {
	/// the type that was expected to be found on the given variable 
	public let expectedType:TokenSyntax
	/// the variable that was actually found
	public let foundType:TokenSyntax?
	public var message:String { "unexpected variable type declaration found. expected to find variable of type \(expectedType) but instad found type \(String(describing:foundType))" }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_missing_type_annotation")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

/// thrown when there is an extraneous variable declaration in the member body that is not expected.
public struct ExtraneousVariableDeclaration:Swift.Error, DiagnosticMessage {
	public var message:String { "extraneous variable declaration found. please move this variable to a standalone extension." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_extraneous_variable_declaration")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

public struct UnimplementedVariableMember:Swift.Error, DiagnosticMessage {
	public var message:String { "this member is not implemented in the attached body. please implement this variable in the body to silence this error." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_unimplemented_member")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

public struct LetBindingSpecifierUnsupported:Swift.Error, DiagnosticMessage {
	public var message:String { "let binding specifiers are not supported in this mode. please remove the let binding specifier from this variable declaration, and replace it with 'var'." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_let_binding_specifier_unsupported")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

public struct RAW_staticbuff_macro:MemberMacro, ExtensionMacro {
	/// defines the two types of usages for this macro code.
	public enum MacroUsageMode {
		/// expand into a static byte buffer of specified length
		case staticBytes(Int)
		/// act as a concat structure that simply is a linear encoding of RAW_staticbuff types
		case concatType([TokenSyntax])
	}

	/// used to determine the mode that this macro is being used in.
	private class NodeUsageParser:SyntaxVisitor {
		var mode:MacroUsageMode? = nil
		override func visit(_ node:DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
			switch mode {
				case nil:
					mode = .concatType([node.baseName])
				case var .concatType(tokens):
					tokens.append(node.baseName)
					mode = .concatType(tokens)
				default:
				break;
			}
			return .skipChildren
		}
		override func visit(_ node:IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
			switch mode {
				case nil:
					mode = .staticBytes(Int(node.literal.text)!)
				default:
				break;
			}
			return .skipChildren
		}
	}

	private class VariableDeclLister:SyntaxVisitor {
		var varDecls = [VariableDeclSyntax]()
		override func visit(_ node:VariableDeclSyntax) -> SyntaxVisitorContinueKind {
			varDecls.append(node)
			return .skipChildren
		}
	}
	private class AccessorBlockLister:SyntaxVisitor {
		var accessorBlocks = [AccessorBlockSyntax]()
		override func visit(_ node:AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
			accessorBlocks.append(node)
			return .skipChildren
		}
	}
	private class TuplePatternLister:SyntaxVisitor {
		var tuplePatterns = [TuplePatternSyntax]()
		override func visit(_ node:TuplePatternSyntax) -> SyntaxVisitorContinueKind {
			tuplePatterns.append(node)
			return .skipChildren
		}
	}
	private class InitializationFinder:SyntaxVisitor {
		var initializers = [InitializerClauseSyntax]()
		override func visit(_ node:InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
			initializers.append(node)
			return .skipChildren
		}
	}
	private class VariableTypeAnnotationFinder:SyntaxVisitor {
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
	private class VariableNameFinder:SyntaxVisitor {
		var name:TokenSyntax? = nil
		override func visit(_ node:PatternBindingSyntax) -> SyntaxVisitorContinueKind {
			guard name == nil else {
				return .skipChildren
			}
			name = node.pattern.as(IdentifierPatternSyntax.self)?.identifier
			return .skipChildren
		}
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		guard node.is(AttributeSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected labeled expression list, found \(String(describing:node.syntaxNodeType))")
			#endif
			fatalError()
		}

		guard declaration.is(StructDeclSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected struct declaration, found \(String(describing:declaration.syntaxNodeType))")
			#endif
			return []
		}

		return [try ExtensionDeclSyntax("""
			extension \(type):RAW_staticbuff {}
		""")]
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		// parse for the attached declaration
		let structFinder = StructFinder(viewMode: .sourceAccurate)
		structFinder.walk(declaration)
		guard let asStruct = structFinder.structDecl else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected struct declaration, found \(String(describing:declaration.syntaxNodeType))")
			#endif
			context.addDiagnostics(from:ExpectedStructAttachment(found:declaration.syntaxNodeType), node:node)
			return []
		}

		// parse for the macro syntax
		let nodeConfig = NodeUsageParser(viewMode: .sourceAccurate)
		nodeConfig.walk(node)
		guard let config = nodeConfig.mode else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("could not parse macro usage.")
			#endif
			fatalError()
		}

		// find the variable decls in the struct
		let varScanner = VariableDeclLister(viewMode:.sourceAccurate)
		varScanner.walk(asStruct)

		var declString = [DeclSyntax]()
		switch config {

			// do not emit a comparison operator for static buffers. this allows the user to write an override to the protocol's default implementation if wanted.
			case .staticBytes(let byteCount):
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

				// throw a diagnostic on any variable declarations that are not computed
				for curVar in varScanner.varDecls {
					let abLister = AccessorBlockLister(viewMode:.sourceAccurate)
					abLister.walk(curVar)
					let staticFinder = StaticModifierFinder(viewMode:.sourceAccurate)
					staticFinder.walk(curVar)

					// functions that are NOT static AND NOT computed are blocked from being used in this macro.
					if abLister.accessorBlocks.count == 0 && staticFinder.foundStaticModifier == nil {
						context.addDiagnostics(from:StoredVariablesUnsupported(), node:curVar)
					}
				}
				
			// emit a comparison operator that equates to a linear execution of the various members of the staticbuff
			case .concatType(let tokens):
				// assemble the primary extension declaration.
				var buildStoreTypes:[String] = []
				for token in tokens {
					buildStoreTypes.append("\(token.text).RAW_staticbuff_storetype")
				}
				declString.append(
					DeclSyntax("""
					/// \(raw:tokens.count)x UInt8 literal type
					\(raw:asStruct.modifiers) typealias RAW_staticbuff_storetype = (\(raw:buildStoreTypes.joined(separator: ", ")))
				"""))
				var tokensDown = tokens
				var varNameVarType = [TokenSyntax:IdentifierTypeSyntax]()
				varLoop: for curVar in varScanner.varDecls {
					if curVar.bindingSpecifier.text == "let" {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("let binding specifiers are not supported in this mode. please remove the let binding specifier from this variable declaration, and replace it with 'var'.")
						#endif
						context.addDiagnostics(from:LetBindingSpecifierUnsupported(), node:curVar.bindingSpecifier)
					}

					if tokensDown.count == 0 {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("extraneous variable declaration found. this variable will be skipped.")
						#endif
						context.addDiagnostics(from:ExtraneousVariableDeclaration(), node:curVar)
						continue varLoop
					}

					let abLister = AccessorBlockLister(viewMode:.sourceAccurate)
					abLister.walk(curVar)
					guard abLister.accessorBlocks.count == 0 else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("this variable was found to have a computed accessor block. this variable will be skipped.")
						#endif
						continue varLoop
					}

					let staticFinder = StaticModifierFinder(viewMode:.sourceAccurate)
					staticFinder.walk(curVar)
					guard staticFinder.foundStaticModifier == nil else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("this variable was found to have a static modifier. this variable will be skipped.")
						#endif
						continue varLoop
					}
					
					// find the type of the variable
					let tupleFinder = TuplePatternLister(viewMode:.sourceAccurate)
					tupleFinder.walk(curVar)
					guard tupleFinder.tuplePatterns.count == 0 else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected exactly one tuple pattern in variable declaration, found \(tupleFinder.tuplePatterns.count)")
						#endif
						context.addDiagnostics(from:TuplePatternBindingsUnsupported(), node:curVar)
						continue varLoop
					}

					let initFinder = InitializationFinder(viewMode:.sourceAccurate)
					initFinder.walk(curVar)
					guard initFinder.initializers.count == 0 else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected exactly one initializer clause in variable declaration, found \(initFinder.initializers.count)")
						#endif
						context.addDiagnostics(from:VariableInitializationUnsupported(), node:curVar)
						continue varLoop
					}

					let typeFinder = VariableTypeAnnotationFinder(viewMode:.sourceAccurate)
					typeFinder.walk(curVar)
					guard let typeAnnotation = typeFinder.typeAnnotation else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected exactly one type annotation in variable declaration, found \(typeFinder.typeAnnotation == nil ? 0 : 2)")
						#endif
						context.addDiagnostics(from:UnexpectedVariableType(expectedType:tokensDown.first!, foundType:nil), node:curVar)
						tokensDown.remove(at:0)
						continue varLoop
					}

					// check that the type annotation matches the expected type
					guard typeAnnotation.name.text == tokensDown.first!.text else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected variable type annotation to be \(tokensDown.first!.text), found \(typeAnnotation.name.text)")
						#endif
						context.addDiagnostics(from:UnexpectedVariableType(expectedType:tokensDown.first!, foundType:typeAnnotation.name), node:curVar)
						tokensDown.remove(at:0)
						continue varLoop
					}

					let varNameFinder = VariableNameFinder(viewMode:.sourceAccurate)
					varNameFinder.walk(curVar)
					guard let varName = varNameFinder.name else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected exactly one variable name in variable declaration, found \(varNameFinder.name == nil ? 0 : 2)")
						#endif
						context.addDiagnostics(from:UnexpectedVariableType(expectedType:tokensDown.first!, foundType:typeAnnotation.name), node:curVar)
						tokensDown.remove(at:0)
						continue varLoop
					}

					tokensDown.remove(at:0)
					varNameVarType[varName] = typeAnnotation
				}

				// flag leftover type tokens (in the macro syntax) as extraneous if they exist.
				for token in tokensDown {
					#if RAWDOG_MACRO_LOG
					mainLogger.error("extraneous type \(token.text) found. this type will be skipped.")
					#endif
					context.addDiagnostics(from:UnimplementedVariableMember(), node:token)
				}

				// write the custom compare function for this type.
				var buildCompare = [String]()
				for (_, curType) in varNameVarType {
					buildCompare.append("""
						compare_result = \(curType.name.text).RAW_compare(lhs_data_seeking:&lhs_seeker, rhs_data_seeking:&rhs_seeker)
						guard compare_result == 0 else {
							return compare_result
						}
					""")
				}
				declString.append(DeclSyntax("""
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
			\(asStruct.modifiers) mutating func RAW_access_staticbuff_mutating<R>(_ body:(UnsafeMutableRawPointer) throws -> R) rethrows -> R {
				return try withUnsafeMutablePointer(to:&self) { buff in
					return try body(buff)
				}
			}
		"""))
		declString.append(DeclSyntax("""
			\(asStruct.modifiers) mutating func RAW_encode(count: inout size_t) {
				count += MemoryLayout<RAW_staticbuff_storetype>.size
			}
		"""))
		declString.append(DeclSyntax("""
			@discardableResult \(asStruct.modifiers) mutating func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
				withUnsafeMutablePointer(to:&self) { buff in
					_ = RAW_memcpy(dest, buff, MemoryLayout<RAW_staticbuff_storetype>.size)!
				}
				return dest.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
			}
		"""))
		declString.append(DeclSyntax("""
			\(asStruct.modifiers) mutating func RAW_access_mutating<R>(_ body: (inout UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R {
				return try withUnsafeMutablePointer(to:&self) { buff in
					var asBuffer = UnsafeMutableBufferPointer<UInt8>(start:UnsafeMutableRawPointer(buff).assumingMemoryBound(to:UInt8.self), count:MemoryLayout<RAW_staticbuff_storetype>.size)
					#if DEBUG
					let storeBuff = asBuffer
					defer {
						assert(asBuffer.baseAddress == storeBuff.baseAddress, "you are not allowed to replace the underlying buffer point on a static stack buffer")
					}
					#endif
					return try body(&asBuffer)
				}
			}
		"""))
		declString.append(DeclSyntax("""
			\(asStruct.modifiers) static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:size_t, rhs_data:UnsafeRawPointer, rhs_count:size_t) -> Int32 {
				#if DEBUG
				assert(lhs_count == MemoryLayout<RAW_staticbuff_storetype>.size, "lhs_count: \\(lhs_count) != MemoryLayout<RAW_staticbuff_storetype>.size: \\(MemoryLayout<RAW_staticbuff_storetype>.size)")
				assert(rhs_count == MemoryLayout<RAW_staticbuff_storetype>.size, "rhs_count: \\(rhs_count) != MemoryLayout<RAW_staticbuff_storetype>.size: \\(MemoryLayout<RAW_staticbuff_storetype>.size)")
				#endif
				return RAW_compare(lhs_data:lhs_data, rhs_data:rhs_data)
			}
		"""))
		
		return declString
	}
}