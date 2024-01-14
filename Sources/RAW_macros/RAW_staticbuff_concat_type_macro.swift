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
		var inheritances:Set<IdentifierTypeSyntax>? = nil
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
		override func visit(_ node:InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found inheritance clause: '\(node)'...")
			#endif
			if inheritances == nil {
				let idLister = IdTypeLister(viewMode:.sourceAccurate)
				idLister.walk(node)
				inheritances = idLister.listedIDTypes
				return .skipChildren
			}
			return .skipChildren
		}
	}
	
	fileprivate struct ParsedConfiguration {
		let modifiers:DeclModifierListSyntax
		let structName:TokenSyntax
		let inheritedTypes:Set<IdentifierTypeSyntax>
		let concatStructure:[(name:IdentifierPatternSyntax, type:IdentifierTypeSyntax)]
		let rawStaticbuffStoretype:String
		let rawStaticbuffSynthesizedFromNames:String
	}
	fileprivate static func parse(node: SwiftSyntax.AttributeSyntax, attachedTo decl:DeclGroupSyntax, context:SwiftSyntaxMacros.MacroExpansionContext) throws -> ParsedConfiguration {
		guard let asStruct = decl.as(StructDeclSyntax.self) else {
			context.addDiagnostics(from: Diagnostics.expectedStructDeclaration(decl.syntaxNodeType), node: decl)
			throw Diagnostics.expectedStructDeclaration(decl.syntaxNodeType)
		}
		let attachedName = asStruct.name
		let modifiers = asStruct.modifiers

		#if RAWDOG_MACRO_LOG
		mainLogger.info("found struct '\(attachedName.text)' with '\(modifiers.count)' modifiers")
		#endif

		// parse the node's arguments.
		let expectedTypes = NodeParser(viewMode: .sourceAccurate)
		expectedTypes.walk(node)
		guard expectedTypes.foundArgList.count > 1 else {
			context.addDiagnostics(from: Diagnostics.expectedNonEmptyArgumentList, node: node)
			throw Diagnostics.expectedNonEmptyArgumentList
		}
		var implTypes = expectedTypes.foundArgList
		#if RAWDOG_MACRO_LOG
		mainLogger.info("found '\(expectedTypes.foundArgList.count)' expected types")
		#endif

		// parse the attached syntax given the expected types from the node arguments.
		let attachedParser = VariableAndDeclLister(viewMode: .sourceAccurate)
		attachedParser.walk(asStruct)
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
		return ParsedConfiguration(modifiers:modifiers, structName:attachedName, inheritedTypes:attachedParser.inheritances ?? [], concatStructure:buildNames, rawStaticbuffStoretype:buildRAW_staticbuff_storetype, rawStaticbuffSynthesizedFromNames:buildRAW_staticbuff_synthesized_from_names)
	}

    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        guard let parsed = try? parse(node: node, attachedTo: declaration, context: context) else {
			return []
		}
		let foundInheritances = parsed.inheritedTypes
		var inherByNames = Dictionary(grouping:foundInheritances, by: { $0.name.text }).compactMapValues { $0.first }

		var members = [DeclSyntax]()
		members.append(DeclSyntax("""
			\(parsed.modifiers) typealias RAW_staticbuff_storetype = \(raw:parsed.rawStaticbuffStoretype)
		"""))
		members.append(DeclSyntax("""
			\(parsed.modifiers) var RAW_staticbuff:RAW_staticbuff_storetype {
				return \(raw:parsed.rawStaticbuffSynthesizedFromNames)
			}
		"""))

		members.append(DeclSyntax("""
			\(parsed.modifiers) mutating func RAW_access_mutating<R>(_ body:(UnsafeMutableRawPointer, size_t) throws -> R) rethrows -> R {
				return try withUnsafeMutablePointer(to:&self) {
					return try body($0, MemoryLayout<RAW_staticbuff_storetype>.size)
				}
			}
		"""))
		members.append(DeclSyntax("""
			\(parsed.modifiers) func RAW_access<R>(_ body:(UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
				return try withUnsafePointer(to:self) {
					return try body($0, MemoryLayout<RAW_staticbuff_storetype>.size)
				}
			}
		"""))
		members.append(DeclSyntax("""
			\(parsed.modifiers) init(RAW_staticbuff ptr:UnsafeRawPointer) {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is unexpected and breaks the assumptions that allow this macro to work")
				assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "static buffer type alignment mismatch. this is unexpected and breaks the assumptions that allow this macro to work")
				assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "static buffer type stride mismatch. this is unexpected and breaks the assumptions that allow this macro to work")
				#endif
				self = ptr.load(as:Self.self)
			}
		"""))
		members.append(DeclSyntax("""
			\(parsed.modifiers) func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
				return withUnsafePointer(to:self) {
					dest.copyMemory(from:$0, byteCount:MemoryLayout<RAW_staticbuff_storetype>.size)
					return dest.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
				}
			}
		"""))

		var buildCompare = """
		var lhs_seeker = lhs_data
		var rhs_seeker = rhs_data
		var precomp_lhs:UnsafeRawPointer
		var precomp_rhs:UnsafeRawPointer
		var compareResult:Int32 = 0

		"""
		for curCompare in parsed.concatStructure {
			buildCompare += """
			#if DEBUG
			precomp_lhs = lhs_seeker
			precomp_rhs = rhs_seeker
			#endif
			compareResult = \(curCompare.type.name.text).RAW_compare(lhs_data_seeking:&lhs_seeker, rhs_data_seeking:&rhs_seeker)
			#if DEBUG 
			assert(lhs_seeker == precomp_lhs.advanced(by:MemoryLayout<\(curCompare.type.name.text)>.size), "unexpected seek length. this is unexpected and breaks the assumptions that allow this macro to work")
			assert(rhs_seeker == precomp_rhs.advanced(by:MemoryLayout<\(curCompare.type.name.text)>.size), "unexpected seek length. this is unexpected and breaks the assumptions that allow this macro to work")
			#endif
			switch compareResult {
				case 0:
					break
				default:
					return compareResult
			}
			"""
		}
		buildCompare += """
		return compareResult

		"""
		members.append(DeclSyntax("""
			\(parsed.modifiers) static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
				\(raw:buildCompare)
			}
		"""))

		if inherByNames["Hashable"] != nil {
			members.append(DeclSyntax("""
				\(parsed.modifiers) func hash(into hasher:inout Hasher) {
					RAW_access { 
						let asBuffer = UnsafeRawBufferPointer(start:$0, count:MemoryLayout<RAW_staticbuff_storetype>.size)
						hasher.combine(bytes:asBuffer)
					}
				}
			"""))
			inherByNames["Hashable"] = nil
		}

		if inherByNames["Equatable"] != nil {
			members.append(DeclSyntax("""
				\(parsed.modifiers) static func == (lhs:Self, rhs:Self) -> Bool {
					return lhs.RAW_access { lhsBuff in
						rhs.RAW_access { rhsBuff in
							return RAW_memcmp(lhsBuff, rhsBuff, MemoryLayout<RAW_staticbuff_storetype>.size) == 0
						}
					}
				}
			"""))
			inherByNames["Equatable"] = nil
		}
		return members
    }

    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
       guard let structName = declaration.as(StructDeclSyntax.self)?.name else {
			return []
	   }
	   return [try ExtensionDeclSyntax("""
			extension \(structName):RAW_staticbuff, RAW_comparable {}
		""")]
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