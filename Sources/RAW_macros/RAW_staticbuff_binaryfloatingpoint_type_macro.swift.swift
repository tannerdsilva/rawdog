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
		internal let floatType:IdentifierTypeSyntax
		internal var inheritedTypes:Set<IdentifierTypeSyntax> = []
	}

	/// parses the available syntax to determine how this macro should expand (based on user configuration).
	internal static func parseUsageConfig(node:SwiftSyntax.AttributeSyntax, attachedTo declaration:SyntaxProtocol, context:SwiftSyntaxMacros.MacroExpansionContext) -> UsageConfiguration? {
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
		return UsageConfiguration(floatType:foundType, inheritedTypes:inheritedTypes)
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		guard let _ = declaration.as(StructDeclSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected struct declaration, found \(String(describing:declaration.syntaxNodeType))")
			#endif
			context.addDiagnostics(from:ExpectedStructAttachment(found:declaration.syntaxNodeType), node:node)
			return []
		}
		return []
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		guard let asStruct = declaration.as(StructDeclSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected struct declaration, found \(String(describing:declaration.syntaxNodeType))")
			#endif
			return []
		}
		guard let pconfig = Self.parseUsageConfig(node:node, attachedTo:declaration, context:context) else {
			return []
		}
		var buildSyntax:[ExtensionDeclSyntax] = []
		for proto in protocols {
			let pnam = proto.as(IdentifierTypeSyntax.self)!.name.text
			switch pnam {
				case "RAW_encoded_binaryfloatingpoint":
					buildSyntax.append(try ExtensionDeclSyntax ("""
						extension \(type):\(raw:pnam) {}
					"""))
				case "RAW_comparable":
					buildSyntax.append(try ExtensionDeclSyntax ("""
						extension \(type):\(raw:pnam) {
							\(asStruct.modifiers) static func RAW_compare(lhs_data: UnsafeRawPointer, lhs_count:size_t, rhs_data:UnsafeRawPointer, rhs_count:size_t) -> Int32 {
								#if DEBUG
								assert(lhs_count == MemoryLayout<RAW_staticbuff_storetype>.size, "lhs_count: \\(lhs_count) != MemoryLayout<RAW_staticbuff_storetype>.size: \\(MemoryLayout<RAW_staticbuff_storetype>.size)")
								assert(rhs_count == MemoryLayout<RAW_staticbuff_storetype>.size, "rhs_count: \\(rhs_count) != MemoryLayout<RAW_staticbuff_storetype>.size: \\(MemoryLayout<RAW_staticbuff_storetype>.size)")
								#endif
								let lhs = \(raw:pconfig.floatType)(bitPattern:lhs_data.loadUnaligned(as:\(raw:pconfig.floatType).self))
								let rhs = \(raw:pconfig.floatType)(bitPattern:rhs_data.loadUnaligned(as:\(raw:pconfig.floatType).self))
								if lhs < rhs {
									return -1
								} else if lhs > rhs {
									return 1
								} else {
									return 0
								}
							}
						}
					"""))
				case "RAW_comparable_fixed":
					buildSyntax.append(try ExtensionDeclSyntax ("""
						extension \(type):\(raw:pnam) {
							\(asStruct.modifiers) static func RAW_compare(lhs_data: UnsafeRawPointer, rhs_data: UnsafeRawPointer) -> Int32 {
								let lhs = \(raw:pconfig.floatType)(bitPattern:lhs_data.loadUnaligned(as:\(raw:pconfig.floatType).self))
								let rhs = \(raw:pconfig.floatType)(bitPattern:rhs_data.loadUnaligned(as:\(raw:pconfig.floatType).self))
								if lhs < rhs {
									return -1
								} else if lhs > rhs {
									return 1
								} else {
									return 0
								}
							}
						}
					"""))
				case "RAW_native":
					buildSyntax.append(try ExtensionDeclSyntax ("""
						extension \(type):\(raw:pnam) {
							\(asStruct.modifiers) mutating func RAW_native() -> \(raw:pconfig.floatType) {
								#if DEBUG
								assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
								assert(MemoryLayout<\(raw:pconfig.floatType)>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
								#endif
								return RAW_access_staticbuff_mutating { ptr in
									return \(raw:pconfig.floatType)(bitPattern:ptr.loadUnaligned(as:\(raw:pconfig.floatType).self))
								}
							}

							\(asStruct.modifiers) init(RAW_native native:\(raw:pconfig.floatType)) {
								#if DEBUG
								assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
								assert(MemoryLayout<\(raw:pconfig.floatType)>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
								#endif
								var enc = native.bitPattern
								self.init(RAW_staticbuff:&enc)
							}
						}
					"""))
				case "ExpressibleByIntegerLiteral":
					buildSyntax.append(try ExtensionDeclSyntax ("""
						extension \(type):\(raw:pnam) {
							\(asStruct.modifiers) init(integerLiteral value:Int) {
								let asVal = \(raw:pconfig.floatType)(value)!.bitPattern
								self = withUnsafePointer(to:asVal) { ptr in
									return Self(RAW_staticbuff:ptr)
								}
							}
						}
					"""))
				
				case "ExpressibleByFloatLiteral":
					buildSyntax.append(try ExtensionDeclSyntax ("""
						extension \(type):\(raw:pnam) {
							\(asStruct.modifiers) init(floatLiteral value:\(raw:pconfig.floatType)) {
								self.init(RAW_native:value)
							}
						}
					"""))
				default:
					continue
					// fatalError()
			
			}
		}
		return buildSyntax
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
