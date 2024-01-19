import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

fileprivate let domain = "RAW_staticbuff_concat"
#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:domain)
#endif

public struct RAW_staticbuff_concat_type_macro:MemberMacro, ExtensionMacro {
	// parse the macro node for arguments
	private class NodeParser:SyntaxVisitor {
		var foundArgList:[DeclReferenceExprSyntax] = []
		private class TypeLister:SyntaxVisitor {
			var foundArgList:[DeclReferenceExprSyntax] = []
			override func visit(_ node:DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
				#if RAWDOG_MACRO_LOG
				mainLogger.info("type as passed as argument for macro: '\(node)'")
				#endif
				foundArgList.append(node)
				return .skipChildren
			}
		}
		override func visit(_ node:LabeledExprListSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found labeled expression list: '\(node)'. initiating type lister")
			#endif
			let tl = TypeLister(viewMode:.sourceAccurate)
			tl.walk(node)
			foundArgList = tl.foundArgList
			return .skipChildren
		}
	}
	// for each instance variable that is found in the attached member, parse various parts of the variable declaration.
	private class VarValidator:SyntaxVisitor {
		var varName:IdentifierPatternSyntax? = nil
		var typeAnnotation:IdentifierTypeSyntax? = nil
		var accessorBlock:AccessorBlockSyntax? = nil
		var initializer:InitializerClauseSyntax? = nil
		override func visit(_ node:TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found type annotation pattern: '\(node)'")
			#endif
			let idLister = IdTypeLister(viewMode:.sourceAccurate)
			idLister.walk(node)
			typeAnnotation = idLister.listedIDTypes.first!
			return .skipChildren
		}
		override func visit(_ node:IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found identifier pattern: '\(node)'")
			#endif
			varName = node
			return .skipChildren
		}
		override func visit(_ node:AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found accessor block: '\(node)'")
			#endif
			accessorBlock = node
			return .skipChildren
		}
		override func visit(_ node:InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found initializer clause: '\(node)'")
			#endif
			initializer = node
			return .skipChildren
		}
	}
	private class VariableAndDeclLister:SyntaxVisitor {
		var varDecls = [VariableDeclSyntax]()
		var funcDecls = [FunctionDeclSyntax]()
		override func visit(_ node:VariableDeclSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found variable declaration: '\(node)'...")
			#endif
			varDecls.append(node)
			return .skipChildren
		}
		override func visit(_ node:FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found function declaration: '\(node)'...")
			#endif
			funcDecls.append(node)
			return .skipChildren
		}
	}
	
	fileprivate struct ParsedConfiguration {
		let concatStructure:[(name:IdentifierPatternSyntax, type:IdentifierTypeSyntax)]
		let rawStaticbuffStoretype:String
		let rawStaticbuffSynthesizedFromNames:String
	}

	fileprivate static func parse(node: SwiftSyntax.AttributeSyntax, attachedTo decl:DeclGroupSyntax, context:SwiftSyntaxMacros.MacroExpansionContext) -> ParsedConfiguration? {
		// parse the node's arguments.
		let expectedTypes = NodeParser(viewMode: .sourceAccurate)
		expectedTypes.walk(node)
		guard expectedTypes.foundArgList.count > 1 else {
			context.addDiagnostics(from: Diagnostics.expectedNonEmptyArgumentList, node: node)
			return nil
		}
		var implTypes = expectedTypes.foundArgList
		#if RAWDOG_MACRO_LOG
		mainLogger.info("found '\(expectedTypes.foundArgList.count)' expected types")
		#endif

		// parse the attached syntax given the expected types from the node arguments.
		let attachedParser = VariableAndDeclLister(viewMode: .sourceAccurate)
		attachedParser.walk(decl)
		var buildNames = [(name:IdentifierPatternSyntax, type:IdentifierTypeSyntax)]()
		var buildRAW_staticbuff_storetype = "("
		var buildRAW_staticbuff_synthesized_from_names = "("
		var buildLinearRAW_compareSyntax = [String]()
		for (i, curVar) in attachedParser.varDecls.enumerated() {
			if i < expectedTypes.foundArgList.count {
				defer {
					implTypes.removeFirst()
				}
				let expectedType = expectedTypes.foundArgList[i]
				guard curVar.bindingSpecifier.as(TokenSyntax.self)?.text == "var" else {
					context.addDiagnostics(from:Diagnostics.invalidStoredVariableDeclaration(.mustBeMutableVar), node:curVar)
					continue
				}
				guard curVar.bindings.count == 1 else {
					context.addDiagnostics(from:Diagnostics.invalidStoredVariableDeclaration(.multiplePatternBindingsUnsupported), node:curVar)
					continue
				}
				let varSearcher = VarValidator(viewMode:.sourceAccurate)
				varSearcher.walk(curVar)
				guard varSearcher.accessorBlock == nil else {
					context.addDiagnostics(from:Diagnostics.invalidStoredVariableDeclaration(.variablesCannotHaveAccessors), node:curVar)
					continue
				}
				guard varSearcher.initializer == nil else {
					context.addDiagnostics(from:Diagnostics.invalidStoredVariableDeclaration(.variablesCannotBeInitialized), node:curVar)
					continue
				}
				if let varName = varSearcher.varName, let varType = varSearcher.typeAnnotation {
					guard varType.name.text == expectedType.baseName.text else {
						context.addDiagnostics(from:Diagnostics.invalidStoredVariableDeclaration(.invalidTypeAnnotation(expectedType)), node:curVar)
						context.addDiagnostics(from:VariableNameReminder(variableName:varName.identifier.text, expectedType:expectedType), node:expectedType)
						continue
					}
					buildNames.append((name:varName, type:varType))
				}
			} else {
				context.addDiagnostics(from:Diagnostics.invalidStoredVariableDeclaration(.unexpectedVariable), node:curVar)
			}
		}
		for (i, (vname, curType)) in buildNames.reversed().enumerated().reversed() {
			buildRAW_staticbuff_storetype += "\(curType.name.text)"
			buildRAW_staticbuff_synthesized_from_names += "\(vname.identifier.text)"
			buildLinearRAW_compareSyntax.append("compareResult = \(curType.name.text).RAW_compare(lhs_data_seeking:&lhs_seeker, rhs_data_seeking:&rhs_seeker)")
			if i > 0 {
				buildRAW_staticbuff_storetype += ", "
				buildRAW_staticbuff_synthesized_from_names += ", "
			}
		}
		buildRAW_staticbuff_storetype += ")"
		buildRAW_staticbuff_synthesized_from_names += ")"
		for curFunc in attachedParser.funcDecls {
			context.addDiagnostics(from:Diagnostics.unsupportedFunctionDeclaration, node:curFunc)
		}
		for curUnimplemented in implTypes {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found unimplemented variable declaration: '\(curUnimplemented)'")
			#endif
			context.addDiagnostics(from:Diagnostics.unimplementedStoredVariableDeclaration(expectedTypes.foundArgList.first!), node:curUnimplemented)
		}
		return ParsedConfiguration(concatStructure:buildNames, rawStaticbuffStoretype:buildRAW_staticbuff_storetype, rawStaticbuffSynthesizedFromNames:buildRAW_staticbuff_synthesized_from_names)
	}

    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let asStruct = declaration.as(StructDeclSyntax.self) else {
			context.addDiagnostics(from:ExpectedStructAttachment(found:declaration.syntaxNodeType), node:node)
			return []
		}
		guard let parsed = parse(node: node, attachedTo: declaration, context: context) else {
			return []
		}
		var members = [DeclSyntax]()
		members.append(DeclSyntax("""
			\(asStruct.modifiers) typealias RAW_staticbuff_storetype = \(raw:parsed.rawStaticbuffStoretype)
		"""))

		members.append(DeclSyntax("""
			\(asStruct.modifiers) init(RAW_staticbuff ptr:UnsafeRawPointer) {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is unexpected and breaks the assumptions that allow this macro to work")
				assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "static buffer type alignment mismatch. this is unexpected and breaks the assumptions that allow this macro to work")
				assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "static buffer type stride mismatch. this is unexpected and breaks the assumptions that allow this macro to work")
				#endif
				self = ptr.load(as:Self.self)
			}
		"""))
		
		return members
    }

    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
	   guard let asStruct = declaration.as(StructDeclSyntax.self) else {
		//    context.addDiagnostics(from:ExpectedStructAttachment(found:declaration.syntaxNodeType), node:node)
		   return []
	   }
	   var buildProtos = protocols.count > 0 ? ": " : ""
	   for (i, proto) in protocols.enumerated() {
		   buildProtos += "\(proto)"
		   if i < protocols.count - 1 {
			   buildProtos += ", "
		   }
	   }
	   var buildResults = [ExtensionDeclSyntax]()

		for proto in protocols {
			guard let protoId = proto.as(IdentifierTypeSyntax.self) else {
				#if RAWDOG_MACRO_LOG
				mainLogger.error("expected identifier type, found \(String(describing:proto.syntaxNodeType))")
				#endif
				fatalError()
			}
			let pname = protoId.name.text
			switch pname {
				case "RAW_accessible":
					buildResults.append(try ExtensionDeclSyntax("""
						extension \(type):\(raw:pname) {
							\(asStruct.modifiers) mutating func RAW_access_mutating<R>(_ body:(inout UnsafeMutableBufferPointer<UInt8>) throws -> R) rethrows -> R {
								var makeBuffer = UnsafeMutableBufferPointer<UInt8>(start:&privateBytes, count:MemoryLayout<RAW_staticbuff_storetype>.size)
								#if DEBUG
								let buffCap = makeBuffer.baseAddress
								defer {
									assert(makeBuffer.baseAddress != buffCap, "you cannot change the underlying buffer of a static buffer type. this is a user error.")
								}
								#endif
								return try body(&makeBuffer)
							}
						}
					"""))
				case "RAW_comparable":
					buildResults.append(try ExtensionDeclSyntax("""
						extension \(type):\(raw:pname) {
							\(asStruct.modifiers) static func RAW_compare(lhs_data:UnsafeRawPointer, lhs_count:size_t, rhs_data:UnsafeRawPointer, rhs_count:size_t) -> Int32 {
								#if DEBUG
								assert(lhs_count == MemoryLayout<RAW_staticbuff_storetype>.size, "the size of the left hand side must be equal to the size of the static buffer type. this is an unexpected internal error.")
								assert(rhs_count == MemoryLayout<RAW_staticbuff_storetype>.size, "the size of the right hand side must be equal to the size of the static buffer type. this is an unexpected internal error.")
								#endif
								return RAW_memcmp(lhs_data, rhs_data, MemoryLayout<RAW_staticbuff_storetype>.size)
							}
						}
					"""))

				case "RAW_encodable":
					buildResults.append(try ExtensionDeclSyntax("""
					extension \(type):\(raw:pname) {
						/// encodes the type into the given destination pointer.
						/// - returns: a pointer at the end of the the n + 1 memory stride that occurred during the write
						\(asStruct.modifiers) mutating func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
							#if DEBUG
							assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "the stride of the type must be equal to the stride of the static buffer type. this is an unexpected internal error.")
							assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "the alignment of the type must be equal to the alignment of the static buffer type. this is an unexpected internal error.")
							assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "the size of the type must be equal to the size of the static buffer type. this is an unexpected internal error.")
							#endif
							return withUnsafeMutablePointer(to:&self) { valPtr in
								return RAW_memcpy(dest, valPtr, MemoryLayout<RAW_staticbuff_storetype>.size)!.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
							}
						}

						/// encodes the byte count of the encoding to the given ``size_t`` pointer.
						\(asStruct.modifiers) mutating func RAW_encode(count:inout size_t) {
							#if DEBUG
							assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "the stride of the type must be equal to the stride of the static buffer type. this is an unexpected internal error.")
							assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "the alignment of the type must be equal to the alignment of the static buffer type. this is an unexpected internal error.")
							assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "the size of the type must be equal to the size of the static buffer type. this is an unexpected internal error.")
							#endif
							count += MemoryLayout<RAW_staticbuff_storetype>.size
						}
					}
					"""))
				case "RAW_decodable":
					buildResults.append(try ExtensionDeclSyntax("""
						extension \(type):\(raw:pname) {
							/// initializes the type from a raw pointer. it is assumed that the contents of the pointer are of correct size.
							\(asStruct.modifiers) init?(RAW_decode:UnsafeRawPointer, count:size_t) {
								guard count == MemoryLayout<RAW_staticbuff_storetype>.size else {
									return nil
								}
								self.init(RAW_staticbuff:RAW_decode)
							}
						}
					"""))
				case "RAW_fixed":
					buildResults.append(try ExtensionDeclSyntax("""
						extension \(type):\(raw:pname) {
							\(asStruct.modifiers) typealias RAW_fixed_type = RAW_staticbuff_storetype
						}
					"""))
				case "RAW_convertible_fixed":
					buildResults.append(try ExtensionDeclSyntax("""
						extension \(type):\(raw:pname) {
							/// initializes the type from a raw pointer. it is assumed that the contents of the pointer are of correct size.
							\(asStruct.modifiers) init(RAW_decode ptr:UnsafeRawPointer) {
								self.init(RAW_staticbuff:ptr)
							}
						}
					"""))
				case "RAW_comparable_fixed":
					buildResults.append(try ExtensionDeclSyntax("""
						extension \(type):\(raw:pname) {
							/// compare two instances of the same type.
							\(asStruct.modifiers) static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
								return RAW_memcmp(lhs_data, rhs_data, MemoryLayout<RAW_staticbuff_storetype>.size)
							}
						}
					"""))
				case "RAW_staticbuff":
					buildResults.append(try ExtensionDeclSyntax("""
						extension \(type):\(raw:pname) {}
					"""))
				default:
					#if RAWDOG_MACRO_LOG
					mainLogger.error("unknown protocol name '\(pname)'.")
					#endif
				
			}
		}

		return buildResults
    }

	/// an accent note that is used when Diagnostics.invalidStoredVariable.invalidTypeAnnotation is thrown.
	struct VariableNameReminder:Swift.Error, DiagnosticMessage {
		let variableName:String
		let expectedType:DeclReferenceExprSyntax
		init(variableName:String, expectedType:DeclReferenceExprSyntax) {
			self.variableName = variableName
			self.expectedType = expectedType
		}

		var message:String {
			return "this declares that the variable '\(variableName)' should be of type '\(expectedType.baseName.text)'."
		}

		var diagnosticID:SwiftDiagnostics.MessageID {
			return SwiftDiagnostics.MessageID(domain:domain, id:"variableNameReminder")
		}

		let severity:DiagnosticSeverity = .note
	}
	enum Diagnostics:Swift.Error, DiagnosticMessage {
		case unsupportedInheritance(IdentifierTypeSyntax)

		/// thrown when the concat macro is invoked and attached to a declaration that is not a struct.
		case expectedStructDeclaration(SyntaxProtocol.Type)

		/// thrown when the concat macro is invoked but no types are listed in the varargs list.
		case expectedNonEmptyArgumentList

		enum StoredVarImplementationNote {
			/// thrown when a variable is a let constant when it should be a mutable var.
			case mustBeMutableVar

			case multiplePatternBindingsUnsupported

			case invalidTypeAnnotation(DeclReferenceExprSyntax)

			case variablesCannotHaveAccessors

			case variablesCannotBeInitialized

			case unexpectedVariable
		}
		/// thrown when a user incorrectly implements the stored properties of a static buffer type.
		case invalidStoredVariableDeclaration(StoredVarImplementationNote)

		case unimplementedStoredVariableDeclaration(DeclReferenceExprSyntax)

		case unsupportedFunctionDeclaration
		
		case variableDeclarationsNotSupported

	    var message: String {
			switch self {
				case .unsupportedInheritance(let name):
					return "this macro does not directly implement '\(name)' protocol. if you wish to implement this protocol yourself, you may do so in a standalone extension declaration."
				case .unsupportedFunctionDeclaration:
					return "this macro only supports initialization functions in the base structure declaration. please move this function to an external extension to maintain this functionality."
				case .variableDeclarationsNotSupported:
					return "variable declarations are not supported in the attached structure. please remove any variable declarations from the structure."
				case .unimplementedStoredVariableDeclaration(let expected):
					return "this variable has not been named in the attached structure. please add a variable of type '\(expected.baseName.text)' to the structure."
				case .expectedStructDeclaration(let found):
					return "this macro must be attached to a struct declaration. instead, found \(String(describing:found))"
				case .expectedNonEmptyArgumentList:
					return "this macro must be invoked with at least one type argument."
				case .invalidStoredVariableDeclaration(let note):
					switch note {
						case .multiplePatternBindingsUnsupported:
							return "multiple pattern bindings are not supported in the stored properties of a static buffer type. please write each stored property on its own line."
						case .mustBeMutableVar:
							return "stored properties must be mutable. please change the 'let' binding specifier to 'var'."
						case .invalidTypeAnnotation(let expected):
							return "the type annotation for this stored property is not the correct type. please change the type annotation to '\(expected.baseName.text)'."
						case .variablesCannotHaveAccessors:
							return "variables cannot have accessors. please remove any accessors from the variable."
						case .variablesCannotBeInitialized:
							return "variables cannot be initialized. please remove any initializers from the variable."
						case .unexpectedVariable:
							return "unexpected variable declaration. please remove the variable declaration."
					}
			}
		}

	    var diagnosticID: SwiftDiagnostics.MessageID {
			switch self {
				case .unsupportedInheritance:
					return SwiftDiagnostics.MessageID(domain:domain, id:"unsupportedInheritance")
				case .unimplementedStoredVariableDeclaration:
					return SwiftDiagnostics.MessageID(domain:domain, id:"unimplementedStoredVariableDeclaration")
				case .expectedStructDeclaration:
					return SwiftDiagnostics.MessageID(domain:domain, id:"expectedStructDeclaration")
				case .expectedNonEmptyArgumentList:
					return SwiftDiagnostics.MessageID(domain:domain, id:"expectedNonEmptyArgumentList")
				case .invalidStoredVariableDeclaration:
					return SwiftDiagnostics.MessageID(domain:domain, id:"invalidStoredVariable")
				case .unsupportedFunctionDeclaration:
					return SwiftDiagnostics.MessageID(domain:domain, id:"unsupportedFunctionDeclaration")
				case .variableDeclarationsNotSupported:
					return SwiftDiagnostics.MessageID(domain:domain, id:"variableDeclarationsNotSupported")
			}
		}

	    var severity: SwiftDiagnostics.DiagnosticSeverity {
			return .error
		}

		
	}
	
}
