import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftParser

fileprivate let domain = "RAW_convertible_string_type_macro"
#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:domain)
#endif

internal struct RAW_convertible_string_type_macro:MemberMacro, ExtensionMacro, MemberAttributeMacro {
	enum Diagnostics:Swift.Error, DiagnosticMessage {
	    var message: String {
	        switch self {
			case .unsupportedInheritance(let name):
				return "this macro does not directly implement '\(name)' protocol. if you wish to implement this protocol yourself, you may do so in a standalone extension declaration."

	        case .expectedStructDeclaration(let type):
	            return "this macro expects to be attached to a struct declaration. instead, was attached to type \(type)"
	        }
	    }

	    var diagnosticID: SwiftDiagnostics.MessageID {
			switch self {
			case .unsupportedInheritance:
				return MessageID(domain:domain, id:"unsupportedInheritance")
			case .expectedStructDeclaration:
				return MessageID(domain:domain, id:"expectedStructDeclaration")
			}
	    }

	    var severity: SwiftDiagnostics.DiagnosticSeverity {
			return .error
		}
		case unsupportedInheritance(IdentifierTypeSyntax)
		case expectedStructDeclaration(SyntaxProtocol.Type)
		
	}
	fileprivate class NodeParser:SyntaxVisitor {
		var foundStringEncodingType:IdentifierTypeSyntax? = nil
		override func visit(_ node:GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
			let idLister = IdTypeLister(viewMode:.sourceAccurate)
			idLister.walk(node)
			foundStringEncodingType = idLister.listedIDTypes.first
			return .skipChildren
		}
	}
	fileprivate class AttachedParser:SyntaxVisitor {
		var inheritanceClauseTypes:Set<IdentifierTypeSyntax>? = nil
		override func visit(_ node:InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
			#if RAWDOG_MACRO_LOG
			mainLogger.info("found inheritance clause. identifier types will be scraped and parsing will continue...", metadata:["inheritance": "\(node)"])
			#endif
			if inheritanceClauseTypes == nil {
				let idTypeLister = IdTypeLister(viewMode:.sourceAccurate)
				idTypeLister.walk(node)
				inheritanceClauseTypes = idTypeLister.listedIDTypes
				return .skipChildren
			}
			return .skipChildren
		}
	}
	static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AttributeSyntax] {
		fatalError("\(declaration)")
	}
    static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
        let np = NodeParser(viewMode:.sourceAccurate)
		np.walk(node)
		guard let encodingType = np.foundStringEncodingType else {
			// the macro syntax declaration should enforce that this is always valid
			fatalError()
		}
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			context.addDiagnostics(from:Diagnostics.expectedStructDeclaration(declaration.syntaxNodeType), node:declaration)
			return []
		}
		let attachParser = AttachedParser(viewMode:.sourceAccurate)
		attachParser.walk(structDecl)
		let implementProtocols = attachParser.inheritanceClauseTypes ?? []
		var protocolsByName = Dictionary(grouping:implementProtocols, by: { $0.name.text }).compactMapValues { $0.first }
		var buildDecls = [DeclSyntax]()
		buildDecls.append(DeclSyntax("""
			/// the length of the string without the null terminator
			\(structDecl.modifiers) private(set) var count:size_t
		"""))
		buildDecls.append(DeclSyntax("""
			/// this is stored with a terminating byte for C compatibility but this null terminator is not included in the count variable that this instance stores
			\(structDecl.modifiers) private(set) var bytes:[UInt8]
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) typealias RAW_convertible_unicode_encoding = \(raw:encodingType.name.text)
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) func RAW_encoded_size() -> size_t {
				count
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
				RAW_memcpy(dest, bytes, count)!.advanced(by:count).advanced(by:count)
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) init(RAW_decode: UnsafeRawPointer, count: size_t) {
				self.bytes = [UInt8](unsafeUninitializedCapacity:count, initializingWith: { asBuffer, countout in
					_ = RAW_memcpy(asBuffer.baseAddress!, RAW_decode, count)
					countout = count
				})
				self.count = count
			}
		"""))
		buildDecls.append(DeclSyntax("""
			\(structDecl.modifiers) init(_ string:String) {
				(bytes, count) = string.withCString(encodedAs:\(raw:encodingType.name.text).self, { cString in
					let myLen = RAW_strlen(cString)
					return ([UInt8](unsafeUninitializedCapacity:myLen + 1, initializingWith: { asBuffer, countout in
						_ = RAW_memcpy(asBuffer.baseAddress!, cString, myLen)
						asBuffer[myLen] = 0
						countout = myLen + 1
					}), myLen)
				})
			}
		"""))

		// implement hashable if specified
		if protocolsByName["Hashable"] != nil {
			buildDecls.append(DeclSyntax("""
				\(structDecl.modifiers) func hash(into hasher:inout Hasher) {
					func internalHash(_ ptr:UnsafeRawPointer) {
						let asBuffer = UnsafeRawBufferPointer(start:ptr, count:count)
						hasher.combine(bytes:asBuffer)
					}
					internalHash(bytes)
				}
			"""))
			protocolsByName["Hashable"] = nil
		}

		// implement equatable if specified
		if protocolsByName["Equatable"] != nil {
			buildDecls.append(DeclSyntax("""
				\(structDecl.modifiers) static func == (lhs:Self, rhs:Self) -> Bool {
					return lhs.count == rhs.count && RAW_memcmp(lhs.bytes, rhs.bytes, lhs.count) == 0
				}
			"""))
			protocolsByName["Equatable"] = nil
		}

		// implement comparable if specified
		if protocolsByName["Comparable"] != nil {
			buildDecls.append(DeclSyntax("""
				\(structDecl.modifiers) static func < (lhs:Self, rhs:Self) -> Bool {
					// lexicographical comparison
					let result = RAW_memcmp(lhs.bytes, rhs.bytes, lhs.count < rhs.count ? lhs.count : rhs.count)
					if result == 0 {
						if lhs.count < rhs.count {
							return true
						} else if lhs.count > rhs.count {
							return false
						}
					}
					return result < 0
				}
			"""))
			protocolsByName["Comparable"] = nil
		}

		if protocolsByName["ExpressibleByStringLiteral"] != nil {
			buildDecls.append(DeclSyntax("""
				\(structDecl.modifiers) init(stringLiteral value:String) {
					self.init(value)
				}
			"""))
			protocolsByName["ExpressibleByStringLiteral"] = nil
		}


		// throw an error on all remaining protocols
		for (_, idType) in protocolsByName {
			context.addDiagnostics(from:Diagnostics.unsupportedInheritance(idType), node:declaration)
		}
		return buildDecls
    }

    static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			// diagnostic should be thrown here in the member macro
			fatalError()
		}
		return [
			try ExtensionDeclSyntax("""
				extension \(type):RAW_convertible_unicode {}
			""")
		]
    }

	
}