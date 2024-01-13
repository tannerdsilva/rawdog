import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

fileprivate let domain = "RAW_staticbuff_macro"

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:domain)
#endif

public struct RAW_staticbuff_macro:MemberMacro, ExtensionMacro {
	
	internal struct StaticBuffImplConfiguration {
		internal let modifiers:DeclModifierListSyntax
		internal let structName:String
		internal var storageVariableName:String {
			get {
				return "RAW_staticbuff"
			}
		}

		internal let byteCount:UInt16
		internal let specifiedConforms:Set<IdentifierTypeSyntax>
		internal let isRAWCompareOverridden:Bool

		fileprivate init(modifiers:DeclModifierListSyntax, structName:String, byteCount:UInt16, specifiedConforms:Set<IdentifierTypeSyntax>, isRAWCompareOverridden:Bool) {
			self.modifiers = modifiers
			self.structName = structName
			self.byteCount = byteCount
			self.specifiedConforms = specifiedConforms
			self.isRAWCompareOverridden = isRAWCompareOverridden
		}
	}

	/// parses the static buffer number from the attribute node.
	fileprivate static func parseNodeConfiguration(from node:SwiftSyntax.AttributeSyntax, context:MacroExpansionContext) throws -> UInt16 {
		class NodeParser:SyntaxVisitor {
			var intLiteral:IntegerLiteralExprSyntax? = nil
			var labeledExprList:LabeledExprListSyntax? = nil
			override func visit(_ node:IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found integer literal", metadata:["value": "\(node.literal)"])
				#endif
				intLiteral = node
				return .skipChildren
			}

			override func visit(_ node:LabeledExprListSyntax) -> SyntaxVisitorContinueKind {
				guard node.count == 1 else {
					#if RAWDOG_MACRO_LOG
					mainLogger.error("expected 1 labeled expression, found \(node.count)")
					#endif
					return .skipChildren
				}
				labeledExprList = node
				return .visitChildren
			}
		}
		let nodeParser = NodeParser(viewMode:.sourceAccurate)
		nodeParser.walk(node)
		guard let intLiteral = nodeParser.intLiteral else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected integer literal, found \(String(describing:nodeParser.intLiteral))")
			#endif
			context.addDiagnostics(from:Diagnostics.expectedIntegerLiteral(nodeParser.labeledExprList), node:node)
			throw Diagnostics.expectedIntegerLiteral(nodeParser.labeledExprList)
		}
		guard let intLiteralValue = UInt16("\(intLiteral.literal)") else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected integer literal, found \(String(describing:nodeParser.intLiteral))")
			#endif
			context.addDiagnostics(from:Diagnostics.expectedIntegerLiteral(nodeParser.labeledExprList), node:node)
			throw Diagnostics.expectedIntegerLiteral(nodeParser.labeledExprList)
		}
		return intLiteralValue
	}

	fileprivate static func parseAttachedDeclGroupSyntax(_ declaration:DeclGroupSyntax, node:SwiftSyntax.AttributeSyntax, context:MacroExpansionContext) throws -> StaticBuffImplConfiguration {
		guard let structDecl = declaration.as(StructDeclSyntax.self) else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("expected struct declaration, found \(String(describing:declaration.syntaxNodeType))")
			#endif
			context.addDiagnostics(from:Diagnostics.expectedStructDeclaration(declaration.syntaxNodeType), node:node)
			throw Diagnostics.expectedStructDeclaration(declaration.syntaxNodeType)
		}

		let byteCount = try Self.parseNodeConfiguration(from:node, context:context)

		class AttachedStructSyntaxParser:SyntaxVisitor {
			internal var structName:String? = nil
			internal var modifiers:DeclModifierListSyntax = []
			internal var inheritanceClauseTypes:Set<IdentifierTypeSyntax> = []
			internal var overrideCompare:Bool = false
			internal let context:MacroExpansionContext

			init(context:MacroExpansionContext) {
				self.context = context
				super.init(viewMode:.sourceAccurate)
			}

			override func visit(_ node:CodeBlockSyntax) -> SyntaxVisitorContinueKind {
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found code block", metadata:["block": "\(node)"])
				#endif
				return .skipChildren
			}

			override func visit(_ node:StructDeclSyntax) -> SyntaxVisitorContinueKind {
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found struct declaration", metadata:["name": "\(node.name)"])
				#endif
				structName = node.name.text
				guard let modifiers = node.modifiers.as(DeclModifierListSyntax.self) else {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found struct declaration without modifiers", metadata:["name": "\(node.name)"])
					#endif
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.missingStaticModifier), node:node)
					return .skipChildren
				}
				self.modifiers = modifiers
				return .visitChildren
			}

			override func visit(_ node:VariableDeclSyntax) -> SyntaxVisitorContinueKind {
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("found variable declaration. this is not supported", metadata:["name": "\(node)"])
				#endif
				context.addDiagnostics(from:Diagnostics.variableDeclarationsNotSupported, node:node)
				return .skipChildren
			}

			override func visit(_ node:InheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found inheritance clause. identifier types will be scraped and parsing will continue...", metadata:["inheritance": "\(node)"])
				#endif
				let idTypeLister = IdTypeLister(viewMode:.sourceAccurate)
				idTypeLister.walk(node)
				inheritanceClauseTypes = idTypeLister.listedIDTypes
				return .skipChildren
			}

			// determine if this is a function we are interested in parsing further. other functions may exist, but we are only interested in parsing the override implementation of RAW_compare.
			override func visit(_ node:FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found function declaration", metadata:["name": "\(node.name)"])
				#endif

				guard node.name.text == "RAW_compare" else {
					#if RAWDOG_MACRO_LOG
					mainLogger.info("found non-RAW_compare function declaration", metadata:["name": "\(node.name)"])
					#endif
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.incorrectFunctionName), node:node)
					return .skipChildren
				}
				
				// check for the static modifier.
				if node.modifiers.contains(where: { $0.name.text == "static" }) == false {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found non-static RAW_compare function declaration", metadata:["name": "\(node.name)"])
					#endif
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.missingStaticModifier), node:node)
					return .skipChildren
				}

				#if RAWDOG_MACRO_LOG
				mainLogger.info("found static RAW_compare function declaration. parsing will continue...", metadata:["name": "\(node.name)"])
				#endif

				return .visitChildren
			}

			override func visit(_ node:ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found return clause", metadata:["return": "\(node)"])
				#endif
				guard let returnID = node.type.as(IdentifierTypeSyntax.self) else {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found invalid return type", metadata:["return": "\(node)"])
					#endif
					overrideCompare = false
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.incorrectReturnClause(node)), node:node)
					return .skipChildren
				}
				guard returnID.name.text == "Int32" else {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found invalid return type", metadata:["return": "\(node)"])
					#endif
					overrideCompare = false
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.incorrectReturnClause(node)), node:node)
					return .skipChildren
				}
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found valid return type. this is a valid override.", metadata:["return": "\(node)"])
				#endif
				overrideCompare = true
				return .skipChildren
			}
			
			override func visit(_ node:FunctionEffectSpecifiersSyntax) -> SyntaxVisitorContinueKind {
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found function effect specifiers", metadata:["specifiers": "\(node)"])
				#endif
				guard node.throwsSpecifier == nil else {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found throws specifier", metadata:["specifiers": "\(node)"])
					#endif
					overrideCompare = false
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.functionThrows), node:node)
					return .skipChildren
				}
				guard node.asyncSpecifier == nil else {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found async specifier", metadata:["specifiers": "\(node)"])
					#endif
					overrideCompare = false
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.functionIsAsync), node:node)
					return .skipChildren
				}
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found no function effect specifiers. parsing will continue...", metadata:["specifiers": "\(node)"])
				#endif
				return .visitChildren
			}

			override func visit(_ node:FunctionParameterListSyntax) -> SyntaxVisitorContinueKind {
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found function parameter list", metadata:["params": "\(node)"])
				#endif
				
				guard node.count == 2 else {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found invalid number of parameters", metadata:["params": "\(node)"])
					#endif
					overrideCompare = false
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.incorrectArgumentList(node)), node:node)
					return .skipChildren
				}
				
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found valid parameter list. parsing will continue...", metadata:["params": "\(node)"])
				#endif
				
				guard let firstItem = node[node.startIndex].as(FunctionParameterSyntax.self) else {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found invalid parameter", metadata:["param": "\(node)"])
					#endif
					overrideCompare = false
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.incorrectArgumentList(node)), node:node)
					return .skipChildren
				}
				guard let secondItem = node[node.index(after:node.startIndex)].as(FunctionParameterSyntax.self) else {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found invalid parameter", metadata:["param": "\(node)"])
					#endif
					overrideCompare = false
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.incorrectArgumentList(node)), node:node)
					return .skipChildren
				}

				guard firstItem.firstName.text == "lhs_data" && secondItem.firstName.text == "rhs_data" else {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found invalid parameter name", metadata:["param": "\(node)"])
					#endif
					overrideCompare = false
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.incorrectArgumentList(node)), node:node)
					return .skipChildren
				}

				guard let firstType = firstItem.type.as(IdentifierTypeSyntax.self), let secondType = secondItem.type.as(IdentifierTypeSyntax.self) else {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found invalid parameter type", metadata:["param": "\(node)"])
					#endif
					overrideCompare = false
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.incorrectArgumentList(node)), node:node)
					return .skipChildren
				}

				guard firstType.name.text == "UnsafeRawPointer" && secondType.name.text == "UnsafeRawPointer" else {
					#if RAWDOG_MACRO_LOG
					mainLogger.warning("found invalid parameter type", metadata:["param": "\(node)"])
					#endif
					overrideCompare = false
					context.addDiagnostics(from:Diagnostics.incorrectComparisonOverride(.incorrectArgumentList(node)), node:node)
					return .skipChildren
				}
				return .skipChildren
			}
		}
		let parser = AttachedStructSyntaxParser(context:context)
		parser.walk(declaration)

		return StaticBuffImplConfiguration(modifiers:parser.modifiers, structName:structDecl.name.text, byteCount:byteCount, specifiedConforms:parser.inheritanceClauseTypes, isRAWCompareOverridden:parser.overrideCompare)
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		
		#if RAWDOG_MACRO_LOG
		var logger = mainLogger
		logger[metadataKey: "mtype"] = "extension"
		logger.info("running macro function on node '\(declaration.description).")
		defer {
			logger.info("macro function finished.")
		}
		#endif

		let config = try Self.parseAttachedDeclGroupSyntax(declaration, node:node, context:context)

		// build the returned extensions. starting with the base extension, which makes the type conform to the static buffer protocol.
		let returnResult = [try ExtensionDeclSyntax("""
		// RAW_staticbuff base conformance.
		extension \(raw:config.structName):RAW_staticbuff {
			/// \(raw:config.byteCount)x UInt8 binary representation type.
			\(raw:config.modifiers) typealias RAW_staticbuff_storetype = \(generateUnsignedByteTypeExpression(byteCount:config.byteCount))
		}
		""")]

		return returnResult
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		
		#if RAWDOG_MACRO_LOG
		var logger = mainLogger
		logger[metadataKey: "mtype"] = "members"
		logger.debug("running fixed-length value macro.")
		defer {
			logger.debug("done running fixed-length value macro.")
		}
		#endif
		
		let config = try Self.parseAttachedDeclGroupSyntax(declaration, node:node, context:context)
		
		#if RAWDOG_MACRO_LOG
		logger.trace("got structure name.", metadata:["name": "\(config.structName)"])
		logger.trace("got structure modifiers.", metadata:["mods": "\(config.modifiers)"])
		#endif
		
		// assemble the primary extension declaration.
		var declString:[DeclSyntax] = []

		// insert the default implementation for the compare function if it is not implemented already.
		if config.isRAWCompareOverridden == false {
			#if RAWDOG_MACRO_LOG
			logger.notice("did not find existing RAW_compare function in declaration. a default implementation will be provided.")
			#endif
			declString.append(DeclSyntax("""
				/// compares the raw representation of the type using memcmp.
				\(config.modifiers) static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32 {
					return RAW_memcmp(lhs_data, rhs_data, MemoryLayout<RAW_staticbuff_storetype>.size)
				}
			"""))
		}

		// insert the default implementation for the encode function if it is not implemented already.
		#if RAWDOG_MACRO_LOG
		logger.notice("did not find existing RAW_encode function in declaration. a default implementation will be provided.")
		#endif
		declString.append(DeclSyntax("""
			/// encodes the type into the given destination pointer.
			\(config.modifiers) func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
				return withUnsafePointer(to:\(raw:config.storageVariableName)) { valPtr in
					let sizeValue = MemoryLayout<RAW_staticbuff_storetype>.size
					return RAW_memcpy(dest, valPtr, sizeValue)!.advanced(by:sizeValue)
				}
			}
		"""))

		#if RAWDOG_MACRO_LOG
		logger.notice("did not find any existing RAW_access function in declaration. a default implementation will be provided.")
		#endif
		declString.append(DeclSyntax("""
			/// provides an open pointer to the encoded value. ideally, this is implemented to expose the direct memory of the value, but this is not required. the default implementation encodes the value to a temporary buffer and returns the pointer to that buffer.
			\(config.modifiers) func RAW_access<R>(_ accessFunc: (UnsafeRawPointer, size_t) throws -> R) rethrows -> R {
				return try withUnsafePointer(to:\(raw:config.storageVariableName)) { valPtr in
					return try accessFunc(valPtr, MemoryLayout<RAW_staticbuff_storetype>.size)
				}
			}
		"""))

		#if RAWDOG_MACRO_LOG
		logger.notice("did not find any existing RAW_access_mutating function in declaration. a default implementation will be provided.")
		#endif
		declString.append(DeclSyntax("""
			/// provides an open pointer to the encoded value. ideally, this is implemented to expose the direct memory of the value, but this is not required. the default implementation encodes the value to a temporary buffer and returns the pointer to that buffer.
			\(config.modifiers) mutating func RAW_access_mutating<R>(_ accessFunc: (UnsafeMutableRawPointer, size_t) throws -> R) rethrows -> R {
				return try withUnsafeMutablePointer(to:&\(raw:config.storageVariableName)) { valPtr in
					return try accessFunc(valPtr, MemoryLayout<RAW_staticbuff_storetype>.size)
				}
			}
		"""))

		// insert the default implementation for the decode initializer if it is not implemented already.
		#if RAWDOG_MACRO_LOG
		logger.notice("did not find existing initializer in declaration. a default implementation will be provided.")
		#endif
		declString.append(DeclSyntax("""
			/// initializes the type from a raw pointer. it is assumed that the contents of the pointer are of correct size.
			\(config.modifiers) init(RAW_staticbuff ptr:UnsafeRawPointer) {
				\(raw:config.storageVariableName) = ptr.load(as:RAW_staticbuff_storetype.self)
			}
		"""))

		// insert the default implementation for the byte storage variable if it is not implemented already.
		declString.append(DeclSyntax("""
			/// the byte storage of the type.
			\(config.modifiers) var \(raw:config.storageVariableName):RAW_staticbuff_storetype
		"""))

		var nodeNames = Dictionary(grouping:config.specifiedConforms, by: { $0.name.text })
		
		if nodeNames["Hashable"] != nil {
			#if RAWDOG_MACRO_LOG
			logger.notice("hashable conformance defined in base declaration. this invokes a default implementation.")
			#endif
			declString.append(DeclSyntax("""
				/// implements the raw memory of this type to the swift native hashing protocol.
				\(config.modifiers) func hash(into hasher:inout Swift.Hasher) {
					withUnsafePointer(to:\(raw:config.storageVariableName)) { valPtr in
						let asBufferPointer = UnsafeRawBufferPointer(start:valPtr, count:MemoryLayout<RAW_staticbuff_storetype>.size)
						hasher.combine(bytes:asBufferPointer)
					}
				}
			"""))
			nodeNames["Hashable"] = nil
		}
		if nodeNames["Equatable"] != nil {
			#if RAWDOG_MACRO_LOG
			logger.notice("equatable conformance defined in base declaration. this invokes a default implementation.")
			#endif
			declString.append(DeclSyntax("""
				/// implements native equality checking based on `RAW_compare`.
				\(config.modifiers) static func == (lhs:Self, rhs:Self) -> Bool {
					return withUnsafePointer(to:lhs) { lhsPtr in 
						return withUnsafePointer(to:rhs) { rhsPtr in
							return RAW_compare(lhs_data:lhsPtr, rhs_data:rhsPtr) == 0
						}
					}
				}
			"""))
			nodeNames["Equatable"] = nil
		}
		if nodeNames["Sequence"] != nil {
			#if RAWDOG_MACRO_LOG
			logger.notice("sequence conformance defined in base declaration. this invokes a default implementation.")
			#endif
			declString.append(DeclSyntax("""
				/// implements the sequence protocol by iterating over the bytes of the type.
				\(config.modifiers) func makeIterator() -> RAW_staticbuff_iterator<Self> {
					return RAW_staticbuff_iterator(staticbuff:self)
				}
			"""))
			nodeNames["Sequence"] = nil
		}

		if nodeNames["Collection"] != nil {
			#if RAWDOG_MACRO_LOG
			logger.notice("collection conformance defined in base declaration. this invokes a default implementation.")
			#endif
			declString.append(DeclSyntax("""
				/// implements the collection protocol by iterating over the bytes of the type.
				\(config.modifiers) var startIndex:size_t {
					return 0
				}
				\(config.modifiers) var endIndex:size_t {
					return \(raw:config.byteCount)
				}
				\(config.modifiers) subscript(position:size_t) -> UInt8 {
					get {
						return withUnsafePointer(to:\(raw:config.storageVariableName)) { valPtr in
							return valPtr.withMemoryRebound(to:UInt8.self, capacity:MemoryLayout<UInt8>.size) { bytePtr in
								return bytePtr.advanced(by:position).pointee
							}
						}
					}
				}
				\(config.modifiers) func index(after i:size_t) -> size_t {
					return i + 1
				}
			"""))
			nodeNames["Collection"] = nil
		}

		if nodeNames["ExpressibleByArrayLiteral"] != nil {
			#if RAWDOG_MACRO_LOG
			logger.notice("expressibleByArrayLiteral conformance defined in base declaration. this invokes a default implementation.")
			#endif
			declString.append(DeclSyntax("""
				/// implements the expressibleByArrayLiteral protocol by initializing the type from an array of bytes.
				\(config.modifiers) init(arrayLiteral elements:UInt8...) {
					let asArray = Array(elements)
					guard asArray.count == \(raw:config.byteCount) else {
						fatalError("invalid number of elements in array literal.")
					}
					self.init(RAW_staticbuff:asArray)
				}
			"""))
			nodeNames["ExpressibleByArrayLiteral"] = nil
		}

		if nodeNames["Comparable"] != nil {
			#if RAWDOG_MACRO_LOG
			logger.notice("comparable conformance defined in base declaration. this invokes a default implementation.")
			#endif
			declString.append(DeclSyntax("""
				/// implements the comparable protocol by comparing the raw memory of the type.
				\(config.modifiers) static func < (lhs:Self, rhs:Self) -> Bool {
					return lhs.RAW_access { lhsPtr, _ in
						return rhs.RAW_access { rhsPtr, _ in
							return RAW_compare(lhs_data:lhsPtr, rhs_data:rhsPtr) < 0
						}
					}
				}
			"""))
			nodeNames["Comparable"] = nil
		}

		for leftoverProtocol in nodeNames {
			#if RAWDOG_MACRO_LOG
			logger.warning("found unsupported protocol in base declaration. this will be ignored.", metadata:["protocol": "\(leftoverProtocol.key)"])
			#endif
			context.addDiagnostics(from:Diagnostics.unsupportedInheritance(leftoverProtocol.value.first!), node:leftoverProtocol.value.first!)
		}

		return declString
	}

	internal enum Diagnostics:Swift.Error, DiagnosticMessage {
	    var message: String {
	        switch self {
				case .incorrectComparisonOverride(let note):
					switch note {
						case .incorrectReturnClause(let found):
							return "``RAW_comparable`` implementations must have a return type of ``Int32`` on the 'RAW_compare' function. expected function return type: 'Int32' found: '\(String(describing:found))'. please move this function to an extension declaration if this was not made in error."
						case .incorrectArgumentList(let paramList):
							return "``RAW_comparable`` implementations must have exactly two arguments in the 'RAW_compare' function. expected function argument list: 'lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer' found: '\(paramList)'. please move this function to an extension declaration if this was not made in error."
						case .functionThrows:
							return "``RAW_comparable`` implementations cannot have the 'throws' modifier on the 'RAW_compare' function. please remove the 'throws' modifier to the function declaration or move this function to an extension declaration if this was not made in error."
						case .functionIsAsync:
							return "``RAW_comparable`` implementations cannot have the 'async' modifier on the 'RAW_compare' function. please remove the 'async' modifier to the function declaration or move this function to an extension declaration if this was not made in error."
						case .missingStaticModifier:
							return "``RAW_comparable`` requires the 'static' modifier on the 'RAW_compare' function. please add the 'static' modifier to the function declaration or move this function to an extension declaration if this was not made in error."
						case .incorrectFunctionName:
							return "``RAW_comparable`` implementations must have the name 'RAW_compare' on the function declaration. please rename this function to 'RAW_compare' or move this function to an extension declaration if this was not made in error."
					}
				case .expectedIntegerLiteral(let found):
					return "this macro requires an integer literal as its argument. instead found \(String(describing:found))"
				case .variableDeclarationsNotSupported:
					return "this macro only supports a single stored property in the base declaration. this property must be of type 'RAW_staticbuff_storetype', and must be implemented by this macro directly. as such, this macro does not support the existence of any additional variable declarations in the base declaration. computed properties may be added by the user in standalone extensions."
				case .expectedStructDeclaration(let found):
					return "this macro must be attached to a struct declaration. instead, found \(String(describing:found))"
				case .unsupportedInheritance(let name):
					return "this macro does not directly implement '\(name)' protocol. if you wish to implement this protocol yourself, you may do so in a standalone extension declaration."
	        }
	    }

	    var diagnosticID:SwiftDiagnostics.MessageID {
			switch self {
				case .incorrectComparisonOverride(let note):
					switch note {
						case .incorrectReturnClause(_):
							return SwiftDiagnostics.MessageID(domain:domain, id:"incorrectComparisonOverride.incorrectReturnClause")
						case .incorrectArgumentList(_):
							return SwiftDiagnostics.MessageID(domain:domain, id:"incorrectComparisonOverride.incorrectArgumentList")
						case .functionThrows:
							return SwiftDiagnostics.MessageID(domain:domain, id:"incorrectComparisonOverride.functionThrows")
						case .functionIsAsync:
							return SwiftDiagnostics.MessageID(domain:domain, id:"incorrectComparisonOverride.functionIsAsync")
						case .missingStaticModifier:
							return SwiftDiagnostics.MessageID(domain:domain, id:"incorrectComparisonOverride.missingStaticModifier")
						case .incorrectFunctionName:
							return SwiftDiagnostics.MessageID(domain:domain, id:"incorrectComparisonOverride.incorrectFunctionName")
					}
				case .expectedIntegerLiteral(_):
					return SwiftDiagnostics.MessageID(domain:domain, id:"expectedIntegerLiteral")
				case .variableDeclarationsNotSupported:
					return SwiftDiagnostics.MessageID(domain:domain, id:"variableDeclarationsNotSupported")
				case .expectedStructDeclaration:
					return SwiftDiagnostics.MessageID(domain:domain, id:"expectedStructDeclaration")
				case .unsupportedInheritance(_):
					return SwiftDiagnostics.MessageID(domain:domain, id:"unsupportedInheritance")
			}
		}

	    var severity: SwiftDiagnostics.DiagnosticSeverity {
			return .error
	    }

		public enum ImplementationNote {
			case incorrectReturnClause(ReturnClauseSyntax?)
			case incorrectArgumentList(FunctionParameterListSyntax)
			case missingStaticModifier
			case functionThrows
			case functionIsAsync
			case incorrectFunctionName
		}
		case expectedStructDeclaration(SyntaxProtocol.Type)
		case incorrectComparisonOverride(ImplementationNote)
		case expectedIntegerLiteral(SyntaxProtocol?)
		case variableDeclarationsNotSupported
		case unsupportedInheritance(IdentifierTypeSyntax)
	}
}