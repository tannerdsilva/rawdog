import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:"RAW_staticbuff_floatingpoint_type_macro")
#endif

fileprivate let typeBitpatternTypes:[String:String] = ["Double":"UInt64", "Float":"UInt32"]
fileprivate let typeBitNames:[String:String] = ["Double":"bitPattern", "Float":"bitPattern"]
fileprivate let supportedTypes:[String:UInt16] = ["Double":8, "Float":4]

internal struct RAW_staticbuff_floatingpoint_type_macro:MemberMacro, ExtensionMacro {

	// the primary tool that parses the macro node and determines how it should expand based on user configuration input.

	// primary interpretation tool for the attached syntax.
	fileprivate class InheritedTypeParser:SyntaxVisitor {

		internal var inheritedTypes:Set<IdentifierTypeSyntax> = []

		override func visit(_ node:InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.notice("found inherited type list \(node). parsing will continue.")
			#endif
			let idScanner = IdTypeLister(viewMode:.sourceAccurate)
			idScanner.walk(node)
			inheritedTypes = idScanner.listedIDTypes
			return .skipChildren
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
		internal let floatType:IdentifierTypeSyntax
		internal var inheritedTypes:Set<IdentifierTypeSyntax> = []
		internal var modifierList:DeclModifierListSyntax = []
	}

	/// parses the available syntax to determine how this macro should expand (based on user configuration).
	internal static func parseUsageConfig(node:SwiftSyntax.AttributeSyntax, attachedTo declaration:SyntaxProtocol, context:SwiftSyntaxMacros.MacroExpansionContext) -> UsageConfiguration? {
		guard let asStructDecl = declaration.as(StructDeclSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected the macro to be attached to a struct declaration, but got \(String(describing:declaration))")
			#endif
			context.addDiagnostics(from:Diagnostics.expectedStructDeclaration(declaration.syntaxNodeType), node:declaration)
			return nil
		}
		let structName = asStructDecl.name.text
		let modifiers = asStructDecl.modifiers
		let nodeParser = SingleTypeGenericArgumentFinder(viewMode:.sourceAccurate)
		nodeParser.walk(node)
		guard let foundType = nodeParser.foundType else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected to find a generic argument, but found none.")
			#endif
			return nil
		}
		guard supportedTypes.keys.contains(foundType.name.text) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("unsupported type \(foundType.name.text). supported types are \(supportedTypes.keys.joined(separator:", "))")
			#endif
			context.addDiagnostics(from:Diagnostics.unsupportedFloatingPointType(foundType), node:foundType)
			return nil
		}
		let attachedParser = AttachedSyntaxVisitor(context:context)
		attachedParser.walk(declaration)
		let inheritedTypes = attachedParser.inheritedTypes
		return UsageConfiguration(structName:structName, floatType:foundType, inheritedTypes:inheritedTypes, modifierList:modifiers)
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard let pconfig = Self.parseUsageConfig(node:node, attachedTo:declaration, context:context) else {
			return []
		}
		var inheritedTypeNames = Dictionary(grouping:pconfig.inheritedTypes, by: { $0.name.text }).compactMapValues { $0.first }

		#if RAWDOG_MACRO_LOG
		mainLogger.notice("generating \(pconfig.structName) based on \(pconfig.floatType.name.text) which is \(supportedTypes[pconfig.floatType.name.text]!) bytes. modifiers are \(pconfig.modifierList). inherited types are \(pconfig.inheritedTypes).")
		#endif
		var buildSyntax = [DeclSyntax]()
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) typealias RAW_staticbuff_storetype = \(generateUnsignedByteTypeExpression(byteCount:supportedTypes[pconfig.floatType.name.text]!))
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) var RAW_staticbuff:RAW_staticbuff_storetype
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) init(RAW_staticbuff ptr:UnsafeRawPointer) {
				self.RAW_staticbuff = ptr.load(as:RAW_staticbuff_storetype.self)
			}
		"""))
		buildSyntax.append(DeclSyntax("""
			\(pconfig.modifierList) init(_ native:\(raw:pconfig.floatType.name.text)) {
				self = withUnsafePointer(to:native.\(raw:typeBitNames[pconfig.floatType.name.text]!)) { ptr in
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
				let lhs = \(raw:pconfig.floatType)(\(raw:typeBitNames[pconfig.floatType.name.text]!):lhs_data.loadUnaligned(as:\(raw:typeBitpatternTypes[pconfig.floatType.name.text]!).self))
				let rhs = \(raw:pconfig.floatType)(\(raw:typeBitNames[pconfig.floatType.name.text]!):rhs_data.loadUnaligned(as:\(raw:typeBitpatternTypes[pconfig.floatType.name.text]!).self))
				if lhs < rhs {
					return -1
				} else if lhs > rhs {
					return 1
				} else {
					return 0
				}
			}
		"""))
		if inheritedTypeNames["Hashable"] != nil {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) func hash(into hasher:inout Hasher) {
					RAW_access { buffPtr, _ in
						let asBuffer = UnsafeRawBufferPointer(start:buffPtr, count:MemoryLayout<RAW_staticbuff_storetype>.size)
						hasher.combine(bytes:asBuffer)
					}
				}
			"""))
			inheritedTypeNames["Hashable"] = nil
		}
		if inheritedTypeNames["Equatable"] != nil {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) static func == (lhs:Self, rhs:Self) -> Bool {
					return withUnsafePointer(to:lhs) { lhsPointer in
						return withUnsafePointer(to:rhs) { rhsPointer in
							return Self.RAW_compare(lhs_data:lhsPointer, rhs_data:rhsPointer) == 0
						}
					}
				}
			"""))
			inheritedTypeNames["Equatable"] = nil
		}
		if inheritedTypeNames["Comparable"] != nil {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) static func < (lhs:Self, rhs:Self) -> Bool {
					return withUnsafePointer(to:lhs) { lhsPointer in
						return withUnsafePointer(to:rhs) { rhsPointer in
							return Self.RAW_compare(lhs_data:lhsPointer, rhs_data:rhsPointer) < 0
						}
					}
				}
			"""))
			inheritedTypeNames["Comparable"] = nil
		}

		if inheritedTypeNames["ExpressibleByIntegerLiteral"] != nil {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) init(integerLiteral value:Int) {
					let asFloat = \(raw:pconfig.floatType.name.text)(value)!
					self.init(asFloat)
				}
			"""))
			inheritedTypeNames["ExpressibleByIntegerLiteral"] = nil
		}
		if inheritedTypeNames["ExpressibleByFloatLiteral"] != nil {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) init(floatLiteral value:\(raw:pconfig.floatType.name.text)) {
					self.init(value)
				}
			"""))
			inheritedTypeNames["ExpressibleByFloatLiteral"] = nil
		}

		if inheritedTypeNames["ExpressibleByArrayLiteral"] != nil {
			buildSyntax.append(DeclSyntax("""
				\(pconfig.modifierList) init(arrayLiteral elements:UInt8...) {
					self = Self(RAW_staticbuff:[UInt8](elements))
				}
			"""))
			inheritedTypeNames["ExpressibleByArrayLiteral"] = nil
		}

		for iType in inheritedTypeNames.values {
			context.addDiagnostics(from:Diagnostics.unsupportedInheritance(iType), node:iType)
		}
		
		return buildSyntax
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		guard let pconfig = Self.parseUsageConfig(node:node, attachedTo:declaration, context:context) else {
			return []
		}
		return [try ExtensionDeclSyntax ("""
			extension \(raw:pconfig.structName):RAW_staticbuff {}
		""")]
	}

	public enum Diagnostics:Swift.Error, DiagnosticMessage {
		case functionDeclarationsUnsupported

		case variableDeclarationsNotSupported

		/// expected the macro to be attached to a struct declaration.
		case expectedStructDeclaration(SyntaxProtocol.Type)
	
		/// thrown when this macro is applied to a binaryfloatingpoint type that is not supported.
		case unsupportedFloatingPointType(IdentifierTypeSyntax)

		/// thrown when an inhertance type is found but not supported.
		case unsupportedInheritance(IdentifierTypeSyntax)

		/// the severity of the diagnostic.
		public var severity:DiagnosticSeverity {
			return .error
		}

		public var did:String {
			switch self {
				case .functionDeclarationsUnsupported:
					return "functionDeclarationsUnsupported"
				case .variableDeclarationsNotSupported:
					return "variableDeclarationsNotSupported"
				case .expectedStructDeclaration(_):
					return "expectedStructDeclaration"
				case .unsupportedFloatingPointType(_):
					return "unsupportedFloatingType"
				case .unsupportedInheritance(_):
					return "unsupportedInheritance"
			}
		}

		public var message:String {
			switch self {
				case .functionDeclarationsUnsupported:
					return "function declarations are not supported in a struct expanded with ``@RAW_staticbuff_binaryfloatingpoint_type``."
				case .variableDeclarationsNotSupported:
					return "variable declarations are not supported in a struct expanded with ``@RAW_staticbuff_binaryfloatingpoint_type``."
				case .expectedStructDeclaration(let type):
					return "expected the macro to be attached to a struct declaration, but got \(type)"
				case .unsupportedFloatingPointType(let type):
					return "unsupported type \(type.name.text). supported types are \(supportedTypes.keys.joined(separator:", "))"
				case .unsupportedInheritance(let type):
					return "unsupported inheritance type \(type.name.text). ``@RAW_staticbuff_binaryfloatingpoint_type`` cannot implement this protocol. please declare this inheritance as in a standalone extension."
			}
		}

		public var diagnosticID:MessageID {
			return MessageID(domain:"RAW_staticbuff_binaryinteger_macro", id:self.did)
		}
	}
}
