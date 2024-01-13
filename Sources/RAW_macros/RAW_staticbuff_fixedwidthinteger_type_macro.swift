import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

fileprivate let domain = "RAW_staticbuff_fixedwidthinteger_type_macro"

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:domain)
#endif


internal struct RAW_staticbuff_fixedwidthinteger_type_macro:MemberMacro, ExtensionMacro {

	// the primary tool that parses the macro node and determines how it should expand based on user configuration input.
	internal class MacroSyntaxVisitor:SingleTypeGenericArgumentFinder {
		
		internal var integerBytes:Int? = nil
		internal var isBigEndian:Bool? = nil

		internal let context:MacroExpansionContext

		internal init(context:MacroExpansionContext) {
			self.context = context
			super.init(viewMode:.sourceAccurate)
		}

		override func visit(_ node:LabeledExprSyntax) -> SyntaxVisitorContinueKind {
			switch node.label?.text {
				case "bits":
					guard let intLiteral = node.expression.as(IntegerLiteralExprSyntax.self) else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected an IntegerLiteralExprSyntax for the bits argument, but got \(node.expression)")
						#endif
						return .skipChildren
					}
					guard let bits = Int(intLiteral.literal.text) else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected an integer literal for the bits argument, but got \(intLiteral.literal)")
						#endif
						return .skipChildren
					}
					guard bits % 8 == 0 else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected a multiple of 8 for the bits argument, but got \(bits)")
						#endif
						return .skipChildren
					}
					integerBytes = bits / 8
					return .visitChildren
				case "bigEndian":
					guard let boolLiteral = node.expression.as(BooleanLiteralExprSyntax.self) else {
						#if RAWDOG_MACRO_LOG
						mainLogger.error("expected a BooleanLiteralExprSyntax for the bigEndian argument, but got \(node.expression)")
						#endif
						return .skipChildren
					}
					isBigEndian = (boolLiteral.literal.text == "true")
					return .visitChildren
				default:
					#if RAWDOG_MACRO_LOG
					mainLogger.error("unexpected label \(node.label?.text ?? "<nil>")")
					#endif
					return .skipChildren
			}
		}
	}

	// primary interpretation tool for the attached syntax.
	internal class AttachedSyntaxVisitor:SyntaxVisitor {
		internal let context:MacroExpansionContext
		internal var inheritedTypes:Set<IdentifierTypeSyntax> = []

		init(context:MacroExpansionContext) {
			self.context = context
			super.init(viewMode:.sourceAccurate)
		}

		override func visit(_ node:InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.notice("found inherited type list \(node). parsing will continue.")
			#endif
			let idScanner = IdTypeLister(viewMode:.sourceAccurate)
			idScanner.walk(node)
			inheritedTypes = idScanner.listedIDTypes
			return .skipChildren
		}

		override func visit(_ node:FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.notice("found function declaration \(node). parsing will continue.")
			#endif
			context.addDiagnostics(from:Diagnostics.functionDeclarationsUnsupported, node:node)
			return .skipChildren
		}

		override func visit(_ node:VariableDeclSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.notice("found variable declaration \(node). parsing will continue.")
			#endif
			context.addDiagnostics(from:Diagnostics.variableDeclarationsNotSupported, node:node)
			return .skipChildren
		}
	}
	
	internal struct UsageConfiguration {
		internal let structName:String
		internal let integerType:String
		internal let integerBytes:Int
		internal let isBigEndian:Bool
		internal var endianFunctionName:String {
			return isBigEndian ? "bigEndian" : "littleEndian"
		}
		internal var inheritedTypes:Set<IdentifierTypeSyntax> = []
		internal var modifierList:DeclModifierListSyntax = []
	}

	/// parses the available syntax to determine how this macro should expand (based on user configuration).
	internal static func parseUsageConfig(node:SwiftSyntax.AttributeSyntax, attachedTo declaration:some SyntaxProtocol, context:some SwiftSyntaxMacros.MacroExpansionContext) throws -> UsageConfiguration {
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			context.addDiagnostics(from:Diagnostics.expectedStructDeclaration(declaration.syntaxNodeType), node:declaration)
			throw Diagnostics.expectedStructDeclaration(declaration.syntaxNodeType)
		}
		let attachedStructName = structDecl.name.text
		let modifiers = structDecl.modifiers
		let parser = MacroSyntaxVisitor(context:context)
		parser.walk(node)
		let bytes = parser.integerBytes!
		let isBigEndian = parser.isBigEndian!
		let attachedParser = AttachedSyntaxVisitor(context:context)
		attachedParser.walk(declaration)
		return UsageConfiguration(structName:attachedStructName, integerType:parser.foundType!.name.text, integerBytes:bytes, isBigEndian:isBigEndian, inheritedTypes:attachedParser.inheritedTypes, modifierList:modifiers)
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard let pconfig = try? Self.parseUsageConfig(node:node, attachedTo:declaration, context:context) else {
			return []
		}
		let inheritedTypes = pconfig.inheritedTypes
		let typeExpression = generateUnsignedByteTypeExpression(byteCount:UInt16(pconfig.integerBytes))
		let loadFuncName = pconfig.integerBytes == 1 ? "load" : "loadUnaligned"
		#if RAWDOG_MACRO_LOG
		mainLogger.notice("generating \(pconfig.structName) with \(pconfig.integerType) and \(pconfig.integerBytes) bytes")
		#endif
		var buildSyntax = [DeclSyntax]()
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) typealias RAW_staticbuff_storetype = \(typeExpression)
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) var RAW_staticbuff:RAW_staticbuff_storetype
		"""))
		// no need to reference the loadFunctionName here because we can guarantee that the RAW_staticbuff_storetype is a tuple of UInt8s (always aligned)
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) init(RAW_staticbuff ptr:UnsafeRawPointer) {
				self.RAW_staticbuff = ptr.load(as:RAW_staticbuff_storetype.self)
			}
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) init?(_ native:\(raw:pconfig.integerType)) {
				self = withUnsafePointer(to:native.\(raw:pconfig.endianFunctionName)) { ptr in
					return Self(RAW_staticbuff:ptr)
				}
			}
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) func RAW_encode(dest: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
				return withUnsafePointer(to:RAW_staticbuff) { ptr in
					return RAW_memcpy(dest, ptr, MemoryLayout<RAW_staticbuff_storetype>.size)!.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
				}
			}
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) func RAW_access<R>(_ accessor: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
				return try withUnsafePointer(to:RAW_staticbuff) { ptr in
					return try accessor(ptr, MemoryLayout<RAW_staticbuff_storetype>.size)
				}
			}
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) mutating func RAW_access_mutating<R>(_ accessor: (UnsafeMutableRawPointer, size_t) throws -> R) rethrows -> R {
				return try withUnsafeMutablePointer(to:&RAW_staticbuff) { ptr in
					return try accessor(ptr, MemoryLayout<RAW_staticbuff_storetype>.size)
				}
			}
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
				let lhs = \(raw:pconfig.integerType)(\(raw:pconfig.endianFunctionName):lhs_data.\(raw:loadFuncName)(as:\(raw:pconfig.integerType).self))
				let rhs = \(raw:pconfig.integerType)(\(raw:pconfig.endianFunctionName):rhs_data.\(raw:loadFuncName)(as:\(raw:pconfig.integerType).self))
				if lhs < rhs {
					return -1
				} else if lhs > rhs {
					return 1
				} else {
					return 0
				}
			}
		"""))
		if inheritedTypes.contains(where: { $0.name.text == "Hashable" }) == true {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) func hash(into hasher:inout Hasher) {
					RAW_access { buffPtr, _ in
						let asBuffer = UnsafeRawBufferPointer(start:buffPtr, count:MemoryLayout<RAW_staticbuff_storetype>.size)
						hasher.combine(bytes:asBuffer)
					}
				}
			"""))
		}
		if inheritedTypes.contains(where: { $0.name.text == "Equatable" }) == true {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) static func == (lhs:Self, rhs:Self) -> Bool {
					return withUnsafePointer(to:lhs) { lhsPointer in
						return withUnsafePointer(to:rhs) { rhsPointer in
							return Self.RAW_compare(lhs_data:lhsPointer, rhs_data:rhsPointer) == 0
						}
					}
				}
			"""))
		}
		if inheritedTypes.contains(where: { $0.name.text == "Comparable" }) == true {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) static func < (lhs:Self, rhs:Self) -> Bool {
					return withUnsafePointer(to:lhs) { lhsPointer in
						return withUnsafePointer(to:rhs) { rhsPointer in
							return Self.RAW_compare(lhs_data:lhsPointer, rhs_data:rhsPointer) < 0
						}
					}
				}
			"""))
		}

		if inheritedTypes.contains(where: { $0.name.text == "ExpressibleByIntegerLiteral" }) == true {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) init(integerLiteral value:\(raw:pconfig.integerType)) {
					self = withUnsafePointer(to:value.\(raw:pconfig.endianFunctionName)) { ptr in
						return Self(RAW_staticbuff:ptr)
					}
				}
			"""))
		}

		if inheritedTypes.contains(where: { $0.name.text == "ExpressibleByArrayLiteral" }) == true {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) init(arrayLiteral elements:UInt8...) {
					self = Self(RAW_staticbuff:[UInt8](elements))
				}
			"""))
		}
		
		return buildSyntax
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		let pconfig = try Self.parseUsageConfig(node:node, attachedTo:declaration, context:context)
		return [try ExtensionDeclSyntax ("""
			extension \(raw:pconfig.structName):RAW_staticbuff {}
		""")]
	}

	public enum Diagnostics:Swift.Error, DiagnosticMessage {
	    public var message:String {
			switch self {
				case .expectedStructDeclaration(let node):
					return "``@RAW_staticbuff_fixedwidthinteger_type`` expects to be attached to a struct declaration. instead, found attachment to \(node)"
				case .functionDeclarationsUnsupported:
					return "direct function declarations are not supported in the syntax that ``@RAW_staticbuff_fixedwidthinteger_type`` attaches to. please move this function into a standalone extension."
				case .variableDeclarationsNotSupported:
					return "direct variable declarations are not supported in the syntax that ``@RAW_staticbuff_fixedwidthinteger_type`` attaches to. please implement this variable as a computed property in a standalone extension."
			}
		}

	    public var diagnosticID: SwiftDiagnostics.MessageID {
			switch self {
				case .expectedStructDeclaration(_):
					return MessageID(domain:domain, id:"expectedStructDeclaration")
				case .functionDeclarationsUnsupported:
					return MessageID(domain:domain, id:"functionDeclarationsUnsupported")
				case .variableDeclarationsNotSupported:
					return MessageID(domain:domain, id:"variableDeclarationsNotSupported")
			}
		}

		case expectedStructDeclaration(SyntaxProtocol.Type)
		case functionDeclarationsUnsupported
		case variableDeclarationsNotSupported

		public var severity:DiagnosticSeverity {
			return .error
		}
	}
}