import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

#if RAWDOG_MACRO_LOG
import Logging
fileprivate let mainLogger = Logger(label:"RAW_staticbuff_macro")
#endif

public struct RAW_staticbuff_macro:MemberMacro, ExtensionMacro, MemberAttributeMacro, AccessorMacro, PeerMacro {
	
	internal struct StaticBuffImplConfiguration {
		
		// specifies the protocols that the user specified in the main declaration, implying that the macro should apply default implementations.
		internal enum SpecifiedProtocol:String, Hashable, Equatable {
			case collection = "collection"
			case sequence = "sequence"
			case equatable = "equatable"
			case hashable = "hashable"
			case expressibleByArrayLiteral = "expressiblebyarrayliteral"
		}

		// the only non-optional protocol that is implemented with this macro is RAW_staticbuff. for the functions that this protocol requires, the user may override all but the RAW_staticbuff_storetype.
		internal enum ImplementedFunctions:UInt8, Hashable, Equatable {
			// case decode
			// case encode
			case raw_compare
		}

		internal enum ImplementOrExisting<T> {
			case implement(T)
		}
		
		internal let modifiers:DeclModifierListSyntax
		internal let structName:String
		internal let storageSituation:ImplementOrExisting<TokenSyntax>
		internal var storageVariableName:String {
			get {
				switch storageSituation {
					case .implement(let name):
						return name.text
					// case .existing(let name):
					// 	return name.text
				}
			}
		}
		internal let useUnsigned:Bool
		internal var byteType:IdentifierTypeSyntax {
			get {
				return useUnsigned ? IdentifierTypeSyntax(name:.identifier("UInt8")) : IdentifierTypeSyntax(name:.identifier("Int8"))
			}
		}
		internal let byteCount:UInt16
		internal let specifiedConforms:Set<SpecifiedProtocol>
		internal let implementedFunctions:Set<ImplementedFunctions>

		fileprivate init(modifiers:DeclModifierListSyntax, structName:String, storageSituation:ImplementOrExisting<TokenSyntax>, useUnsigned:Bool, byteCount:UInt16, specifiedConforms:Set<SpecifiedProtocol>, implementedFunctions:Set<ImplementedFunctions>) {
			self.modifiers = modifiers
			self.structName = structName
			self.storageSituation = storageSituation
			self.useUnsigned = useUnsigned
			self.byteCount = byteCount
			self.specifiedConforms = specifiedConforms
			self.implementedFunctions = implementedFunctions
		}
	}

	/// parses the static buffer number from the attribute node.
	fileprivate static func parseNodeConfiguration(from node:SwiftSyntax.AttributeSyntax) throws -> (bytes:UInt16, type:Bool) {
		let labeledExpressionList = node.arguments!.as(LabeledExprListSyntax.self)!
		var getNewNumber:UInt16? = nil
		var getUnsigned:Bool? = nil
		for (i, curItem) in labeledExpressionList.enumerated() {
			switch i {
				case 0:
					// get the number of bytes
					let number = curItem.expression.as(IntegerLiteralExprSyntax.self)!.literal
					guard case .integerLiteral(let value) = number.tokenKind else {
						#if RAWDOG_MACRO_LOG
						mainLogger.critical("expected integer literal")
						#endif
						throw Diagnostics.mustBeIntegerLiteral("\(number)")
					}
					getNewNumber = UInt16(value)
					#if RAWDOG_MACRO_LOG
					mainLogger.info("got attribute number", metadata:["attributeNumber": "\(getNewNumber!)"])
					#endif
				case 1:
					// get the unsigned flag
					let bool = curItem.expression.as(BooleanLiteralExprSyntax.self)!.literal
					switch bool.tokenKind {
						case TokenKind.keyword(.true):
							getUnsigned = true
						case TokenKind.keyword(.false):
							getUnsigned = false
						default:
							#if RAWDOG_MACRO_LOG
							mainLogger.critical("expected boolean literal")
							#endif
							throw Diagnostics.mustBeBooleanLiteral("\(bool)")
					}
					#if RAWDOG_MACRO_LOG
					mainLogger.info("got attribute unsigned flag", metadata:["attributeUnsigned": "\(getUnsigned!)"])
					#endif
				default:
					#if RAWDOG_MACRO_LOG
					mainLogger.critical("expected 2 arguments")
					#endif
					throw Diagnostics.mustBeIntegerLiteral("\(String(describing: node.arguments))")
			}
		}
		return (getNewNumber!, getUnsigned!)
	}

	fileprivate static func parseAttachedDeclGroupSyntax(_ declaration:some DeclGroupSyntax, node:SwiftSyntax.AttributeSyntax) throws -> StaticBuffImplConfiguration {
		let (byteCount, isUnsigned) = try Self.parseNodeConfiguration(from:node)
		let structureName:TokenSyntax
		let structureModifiers:DeclModifierListSyntax
		var inheritedTypes:Set<StaticBuffImplConfiguration.SpecifiedProtocol> = Set()
		var overrideFuncs:Set<StaticBuffImplConfiguration.ImplementedFunctions> = Set()
		var storageIdentifierName:IdentifierPatternSyntax? = nil
		func parseInheritanceTypes(_ ihc:InheritanceClauseSyntax) throws {
			for listItem in ihc.inheritedTypes {
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found inherited type", metadata:["type": "\(listItem)"])
				#endif
				guard let identifierType = listItem.type.as(IdentifierTypeSyntax.self) else {
					#if RAWDOG_MACRO_LOG
					mainLogger.critical("expected identifier type")
					#endif
					throw Diagnostics.mustBeStructOrClassDeclaration(listItem.type.syntaxNodeType)
				}
				guard let asSpecifiedImpl = StaticBuffImplConfiguration.SpecifiedProtocol(rawValue:identifierType.name.text.lowercased()) else {
					#if RAWDOG_MACRO_LOG
					mainLogger.critical("unsupported base conformance")
					#endif
					throw Diagnostics.unsupportedBaseConformance(identifierType.name.text)
				}
				inheritedTypes.insert(asSpecifiedImpl)
			}
		}

		func parseImplementedFunctionsAndVariables(_ memberBlockItemList:MemberBlockItemListSyntax) throws {
			for member in memberBlockItemList {
				switch member.decl.syntaxNodeType {
					// case is InitializerDeclSyntax.Type:
					// 	// goal: seek the only possible initializer declaration type, if it is implemented (it is ok to not be implemented). the initializer should be non-optional.
					// 	#if RAWDOG_MACRO_LOG
					// 	mainLogger.info("found initializer declaration")
					// 	#endif

					// 	let initDecl = member.as(InitializerDeclSyntax.self)!

					// 	// validate that the initializer is not optional.
					// 	guard initDecl.optionalMark == nil else {
					// 		#if RAWDOG_MACRO_LOG
					// 		mainLogger.info("found initializer declaration")
					// 		#endif
					// 		break
					// 	}

					// 	// validate that the function signature perfectly matches 'init(RAW_staticbuff_storetype:UnsafeRawPointer)'
					// 	let parameterList = initDecl.signature.parameterClause.parameters
					// 	guard parameterList.count == 1 else {
					// 		#if RAWDOG_MACRO_LOG
					// 		mainLogger.critical("expected one parameter in initializer declaration")
					// 		#endif
					// 		throw Diagnostics.invalidFunctionOverride("init(RAW_staticbuff_storetype:UnsafeRawPointer)")
					// 	}

					// 	guard let firstParam = parameterList.first?.as(FunctionParameterSyntax.self) else {
					// 		#if RAWDOG_MACRO_LOG
					// 		mainLogger.critical("expected parameter in initializer declaration")
					// 		#endif
					// 		throw Diagnostics.invalidFunctionOverride("init(RAW_staticbuff_storetype:UnsafeRawPointer)")
					// 	}
						
					// 	guard firstParam.firstName.text == "RAW_staticbuff_storetype" else {
					// 		#if RAWDOG_MACRO_LOG
					// 		mainLogger.critical("expected parameter name in initializer declaration")
					// 		#endif
					// 		throw Diagnostics.invalidFunctionOverride("init(RAW_staticbuff_storetype:UnsafeRawPointer)")
					// 	}

					// 	guard let firstParamType = firstParam.type.as(IdentifierTypeSyntax.self) else {
					// 		#if RAWDOG_MACRO_LOG
					// 		mainLogger.critical("expected parameter type in initializer declaration")
					// 		#endif
					// 		throw Diagnostics.invalidFunctionOverride("init(RAW_staticbuff_storetype:UnsafeRawPointer)")
					// 	}

					// 	guard firstParamType.name.text == "UnsafeRawPointer" else {
					// 		#if RAWDOG_MACRO_LOG
					// 		mainLogger.critical("expected parameter type in initializer declaration")
					// 		#endif
					// 		throw Diagnostics.invalidFunctionOverride("init(RAW_staticbuff_storetype:UnsafeRawPointer)")
					// 	}

					// 	#if RAWDOG_MACRO_LOG
					// 	mainLogger.info("found initializer declaration")
					// 	#endif

					// 	overrideFuncs.insert(.decode)

					case is FunctionDeclSyntax.Type:
						// goal: seek the one of two possible function declaration types.
						#if RAWDOG_MACRO_LOG
						mainLogger.info("found function declaration")
						#endif

						let funcDecl = member.decl.as(FunctionDeclSyntax.self)!
						switch funcDecl.name.text {
							case "RAW_compare":
								#if RAWDOG_MACRO_LOG
								mainLogger.info("found RAW_compare function declaration")
								#endif

								// validate that there are only two arguments in the function declaration and that the arguments are of type UnsafeRawPointer.
								let paramList = funcDecl.signature.parameterClause.parameters

								// validate that the function is static
								guard funcDecl.modifiers.contains(where: { $0.name.text == "static" }) else {
									#if RAWDOG_MACRO_LOG
									mainLogger.critical("found non-static RAW_compare function declaration")
									#endif
									throw Diagnostics.invalidFunctionOverride("RAW_compare")
								}

								/// validate that the function has two arguments.
								guard paramList.count == 2 else {
									#if RAWDOG_MACRO_LOG
									mainLogger.critical("found invalid number of arguments in RAW_compare function declaration")
									#endif
									throw Diagnostics.invalidFunctionOverride("RAW_compare")
								}
								guard let lhsParam = paramList.first!.as(FunctionParameterSyntax.self), let lhsType = lhsParam.type.as(IdentifierTypeSyntax.self), let rhsParam = paramList.last!.as(FunctionParameterSyntax.self), let rhsType = rhsParam.type.as(IdentifierTypeSyntax.self) else {
									#if RAWDOG_MACRO_LOG
									mainLogger.critical("found invalid argument type in RAW_compare function declaration")
									#endif
									throw Diagnostics.invalidFunctionOverride("RAW_compare")
								}

								guard lhsParam.firstName.text == "lhs_data" && rhsParam.firstName.text == "rhs_data" else {
									#if RAWDOG_MACRO_LOG
									mainLogger.critical("found invalid argument name in RAW_compare function declaration")
									#endif
									throw Diagnostics.invalidFunctionOverride("RAW_compare")
								}
								
								guard lhsType.name.text == "UnsafeRawPointer" && rhsType.name.text == "UnsafeRawPointer" else {
									#if RAWDOG_MACRO_LOG
									mainLogger.critical("found invalid argument type in RAW_compare function declaration")
									#endif
									throw Diagnostics.invalidFunctionOverride("RAW_compare")
								}

								#if RAWDOG_MACRO_LOG
								mainLogger.info("found valid RAW_compare function declaration")
								#endif
								
								overrideFuncs.insert(.raw_compare)

							// case "RAW_encode":
							// 	#if RAWDOG_MACRO_LOG
							// 	mainLogger.info("found RAW_encode function declaration")
							// 	#endif

							// 	// validate that there is only one argument in the function declaration and that the argument is of type UnsafeMutableRawPointer.
							// 	let paramList = funcDecl.signature.parameterClause.parameters

							// 	// validate that the function is NOT static
							// 	guard funcDecl.modifiers.contains(where: { $0.name.text == "static" }) == false else {
							// 		#if RAWDOG_MACRO_LOG
							// 		mainLogger.critical("found static RAW_encode function declaration. this function should be non-static.")
							// 		#endif
							// 		throw Diagnostics.invalidFunctionOverride("RAW_encode")
							// 	}

							// 	// validate that the function has one argument.
							// 	guard paramList.count == 1 else {
							// 		#if RAWDOG_MACRO_LOG
							// 		mainLogger.critical("found invalid number of arguments in RAW_encode function declaration")
							// 		#endif
							// 		throw Diagnostics.invalidFunctionOverride("RAW_encode")
							// 	}

							// 	guard let destParam = paramList.first!.as(FunctionParameterSyntax.self), let destType = destParam.type.as(IdentifierTypeSyntax.self) else {
							// 		#if RAWDOG_MACRO_LOG
							// 		mainLogger.critical("found invalid argument type in RAW_encode function declaration")
							// 		#endif
							// 		throw Diagnostics.invalidFunctionOverride("RAW_encode")
							// 	}

							// 	guard destParam.firstName.text == "dest" else {
							// 		#if RAWDOG_MACRO_LOG
							// 		mainLogger.critical("found invalid argument name in RAW_encode function declaration")
							// 		#endif
							// 		throw Diagnostics.invalidFunctionOverride("RAW_encode")
							// 	}

							// 	guard destType.name.text == "UnsafeMutableRawPointer" else {
							// 		#if RAWDOG_MACRO_LOG
							// 		mainLogger.critical("found invalid argument type in RAW_encode function declaration")
							// 		#endif
							// 		throw Diagnostics.invalidFunctionOverride("RAW_encode")
							// 	}

							// 	#if RAWDOG_MACRO_LOG
							// 	mainLogger.info("found valid RAW_encode function declaration")
							// 	#endif

							// 	overrideFuncs.insert(.encode)		

							default:
								#if RAWDOG_MACRO_LOG
								mainLogger.critical("found invalid function declaration")
								#endif
								throw Diagnostics.invalidFunctionOverride(funcDecl.name.text)
						}
					
					case is VariableDeclSyntax.Type: 
						// goal: seek the storage value, if it is implemented (it is ok to not be implemented). the storage value should be the ONLY stored property in the declaration. it should be of type RAW_staticbuff_storetype.
						let varDecl = member.as(VariableDeclSyntax.self)!

						// validate that there is only one binding in the declaration.
						let bindingList = varDecl.bindings
						guard bindingList.count == 1 else {
							#if RAWDOG_MACRO_LOG
							mainLogger.critical("found multiple variable assignments in declaration syntax.")
							#endif
							throw Diagnostics.invalidStoredProperty(varDecl)
						}

						// parse the syntax elements of the binding, leading to the type annotation and name of the variable.
						guard let onlyBindingItem = varDecl.bindings.first!.as(PatternBindingSyntax.self) else {
							#if RAWDOG_MACRO_LOG
							mainLogger.critical("found multiple variable assignments in declaration syntax.")
							#endif
							throw Diagnostics.invalidStoredProperty(varDecl)
						}

						// validate that the type annotation is correct.
						guard let typeAnnotation = onlyBindingItem.typeAnnotation?.as(TypeAnnotationSyntax.self), let typeIdentifier = typeAnnotation.type.as(IdentifierTypeSyntax.self), typeIdentifier.name.text == "RAW_staticbuff_storetype" else {
							#if RAWDOG_MACRO_LOG
							mainLogger.info("invalid type annotation.")
							#endif
							throw Diagnostics.invalidStoredProperty(varDecl)
						}
						
						guard let identifierPattern = onlyBindingItem.pattern.as(IdentifierPatternSyntax.self) else {
							#if RAWDOG_MACRO_LOG
							mainLogger.critical("invalid identifier pattern.")
							#endif
							throw Diagnostics.invalidStoredProperty(varDecl)
						}

						storageIdentifierName = identifierPattern
					default:
						break
				}
			}
		}

		switch declaration.syntaxNodeType {
			case is StructDeclSyntax.Type:
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found struct declaration")
				#endif
				let structDecl = declaration.as(StructDeclSyntax.self)!
				structureName = structDecl.name
				structureModifiers = structDecl.modifiers
				if let inheritanceClause = structDecl.inheritanceClause {
					try parseInheritanceTypes(inheritanceClause)
				}
				try parseImplementedFunctionsAndVariables(structDecl.memberBlock.as(MemberBlockSyntax.self)!.members)
				break
			case is ClassDeclSyntax.Type:
				#if RAWDOG_MACRO_LOG
				mainLogger.info("found class declaration")
				#endif
				let classDecl = declaration.as(ClassDeclSyntax.self)!
				structureName = classDecl.name
				structureModifiers = classDecl.modifiers
				if let inheritanceClause = classDecl.inheritanceClause {
					try parseInheritanceTypes(inheritanceClause)
				}
				try parseImplementedFunctionsAndVariables(classDecl.memberBlock.as(MemberBlockSyntax.self)!.members)
				break
			default:
				#if RAWDOG_MACRO_LOG
				mainLogger.critical("expected struct or class declaration. found \(declaration)")
				#endif
				throw Diagnostics.mustBeStructOrClassDeclaration(declaration.syntaxNodeType)
		}
		let calculateStorageSituation:StaticBuffImplConfiguration.ImplementOrExisting<TokenSyntax> = .implement(TokenSyntax.identifier("storage"))

		return StaticBuffImplConfiguration(modifiers:structureModifiers, structName:structureName.text, storageSituation:calculateStorageSituation, useUnsigned:isUnsigned, byteCount:byteCount, specifiedConforms:inheritedTypes, implementedFunctions:overrideFuncs)
	}
	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AttributeSyntax] {
		return []
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AccessorDeclSyntax] {
		return []
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		return []
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

		let config = try Self.parseAttachedDeclGroupSyntax(declaration, node:node)

		// build the returned extensions. starting with the base extension, which makes the type conform to the static buffer protocol.
		let returnResult = [try ExtensionDeclSyntax("""
		// RAW_staticbuff base conformance.
		extension \(raw:config.structName):RAW_staticbuff {
			/// \(raw:config.byteCount)x \(raw:config.byteType) binary representation type.
			\(raw:config.modifiers) typealias RAW_staticbuff_storetype = \(generateTypeExpression(useUnsigned:config.useUnsigned, byteCount:config.byteCount))
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
		
		let config = try Self.parseAttachedDeclGroupSyntax(declaration, node:node)
		
		#if RAWDOG_MACRO_LOG
		logger.trace("got structure name.", metadata:["name": "\(config.structName)"])
		logger.trace("got structure modifiers.", metadata:["mods": "\(config.modifiers)"])
		#endif
		
		// assemble the primary extension declaration.
		var declString:[DeclSyntax] = []

		// insert the default implementation for the compare function if it is not implemented already.
		if config.implementedFunctions.contains(.raw_compare) == false {
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
		logger.notice("did not find any existing RAW_staticbuff function in declaration. a default implementation will be provided.")
		#endif
		declString.append(DeclSyntax("""
			/// returns the underlying memory of the type.
			\(config.modifiers) func RAW_staticbuff() -> RAW_staticbuff_storetype {
				return \(raw:config.storageVariableName)
			}
		"""))

		// insert the default implementation for the decode initializer if it is not implemented already.
		#if RAWDOG_MACRO_LOG
		logger.notice("did not find existing initializer in declaration. a default implementation will be provided.")
		#endif
		declString.append(DeclSyntax("""
			/// initializes the type from a raw pointer. it is assumed that the contents of the pointer are of correct size.
			\(config.modifiers) init(RAW_staticbuff_storetype ptr:UnsafeRawPointer) {
				storage = ptr.load(as:RAW_staticbuff_storetype.self)
			}
		"""))

		// insert the default implementation for the byte storage variable if it is not implemented already.
		switch config.storageSituation {
			case .implement(let name):
				#if RAWDOG_MACRO_LOG
				logger.notice("did not find existing storage variable in declaration. a storage variable will be implemented.", metadata:["name": "\(name)"])
				#endif

				declString.append(DeclSyntax("""
					/// the byte storage of the type.
					private var \(name):RAW_staticbuff_storetype
				"""))
		}

		if config.specifiedConforms.contains(.hashable) {
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
		}
		if config.specifiedConforms.contains(.equatable) {
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
		}
		if config.specifiedConforms.contains(.sequence) {
			#if RAWDOG_MACRO_LOG
			logger.notice("sequence conformance defined in base declaration. this invokes a default implementation.")
			#endif
			declString.append(DeclSyntax("""
				/// implements the sequence protocol by iterating over the bytes of the type.
				\(config.modifiers) func makeIterator() -> RAW_staticbuff_iterator<Self> {
					return RAW_staticbuff_iterator(staticbuff:self)
				}
			"""))
		}

		if config.specifiedConforms.contains(.collection) {
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
		}

		if config.specifiedConforms.contains(.expressibleByArrayLiteral) {
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
					self.init(RAW_staticbuff_storetype:asArray)
				}
			"""))
		}


		return declString
	}

	public enum Diagnostics:Swift.Error, DiagnosticMessage {
		/// thrown when this macro is attached to a declaration that is not a class
		case mustBeIntegerLiteral(String)

		/// thrown when there is not a boolean literal that is expressed in the "unsigned" argument.
		case mustBeBooleanLiteral(String)

		/// thrown when this macro is attached to a declaration that is not a structure or class
		case mustBeStructOrClassDeclaration(SyntaxProtocol.Type)

		/// thrown when the base declaration includes a protocol that is not supported by this macro.
		/// - note: any users that desire to implement unsupported protocols onto their declarations can do so with standalone extensions. by placing a conformance directly at the declaration, the user is implying that they want the macro to provide default implementations.
		case unsupportedBaseConformance(String)

		/// thrown when the user declares an invalid function in the base declaration the macro is attached to.
		/// - this macro supports overriding any of the functions required to conform to the RAW_staticbuff protoco (with the exception of the RAW_staticbuff_storetype typealias, which is based on user configurable parameters anyways).
		/// - supported overrides are:
		/// 	- init(RAW_staticbuff_storetype:UnsafeRawPointer)
		///		- [static] func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32
		///		- func RAW_encode(dest:UnsafeMutableRawPointer) -> UnsafeMutableRawPointer
		/// - overrides may be declared ONLY in the base declaration.
		case invalidFunctionOverride(String)

		/// thrown when the user declares an invalid variable in the base declaration the macro is attached to.
		/// - ``RAW_staticbuff`` macro only supports a single stored property in the base declaration. this property must be of type ``RAW_staticbuff_storetype``.
		case invalidStoredProperty(VariableDeclSyntax)
	
		/// the severity of the diagnostic.
		public var severity:DiagnosticSeverity {
			return .error
		}

		public var did:String {
			switch self {
				case .mustBeIntegerLiteral:
					return "RAW_staticbuff_macro.mustBeIntegerLiteral"
				case .mustBeStructOrClassDeclaration:
					return "RAW_staticbuff_macro.mustBeStructOrClassDeclaration"
				case .mustBeBooleanLiteral(_):
					return "RAW_staticbuff_macro.mustBeBooleanLiteral"
				case .unsupportedBaseConformance(_):
					return "RAW_staticbuff_macro.unsupportedBaseConformance"
				case .invalidFunctionOverride(_):
					return "RAW_staticbuff_macro.invalidFunctionOverride"
				case .invalidStoredProperty(_):
					return "RAW_staticbuff_macro.invalidStoredProperty"
				
			}
		}

		public var message:String {
			switch self {
				case .mustBeIntegerLiteral(let found):
					return "this macro requires an integer literal as its argument. instead found \(found)"
				case .mustBeStructOrClassDeclaration(let declType):
					return "this macro must be attached to a struct or class declaration. instead found \(declType)"
				case .mustBeBooleanLiteral(let found):
					return "this macro requires a boolean literal as its argument. instead found \(found)"
				case .unsupportedBaseConformance(let name):
					return "this macro does not directly implement '\(name)' protocol. if you wish to implement this protocol yourself, you may do so in a standalone extension declaration."
				case .invalidFunctionOverride(let name):
					return "this macro does not support overriding the '\(name)' function. if you wish to implement this function yourself, you may do so in a standalone extension declaration."
				case .invalidStoredProperty(let decl):
					return "this macro only supports a single stored property in the base declaration. this property must be of type 'RAW_staticbuff_storetype'. instead found \(decl)."
			}
		}

		public var diagnosticID:MessageID {
			return MessageID(domain:"RAW_macros", id:self.did)
		}
	}
}

fileprivate func generateTypeExpression(useUnsigned:Bool, byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	switch useUnsigned {
		case true:
			return generateUnsignedByteTypeExpression(byteCount:byteCount)
		case false:
			return generateSignedByteTypeExpression(byteCount:byteCount)
	}
}

fileprivate func generateSignedByteTypeExpression(byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	return generateTypeExpression(typeSyntax:IdentifierTypeSyntax(name:.identifier("Int8")), byteCount:byteCount)
}
fileprivate func generateUnsignedByteTypeExpression(byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	return generateTypeExpression(typeSyntax:IdentifierTypeSyntax(name:.identifier("UInt8")), byteCount:byteCount)
}
fileprivate func generateTypeExpression(typeSyntax:IdentifierTypeSyntax, byteCount:UInt16) -> SwiftSyntax.TupleTypeSyntax {
	var buildContents = TupleTypeElementListSyntax()
	var i:UInt16 = 0
	while i < byteCount {
		var byteTypeElement = TupleTypeElementSyntax(type:typeSyntax)
		byteTypeElement.trailingComma = i + 1 < byteCount ? TokenSyntax.commaToken() : nil
		buildContents.append(byteTypeElement)
		i += 1
	}
	return TupleTypeSyntax(leftParen:TokenSyntax.leftParenToken(), elements:buildContents, rightParen:TokenSyntax.rightParenToken())
}
