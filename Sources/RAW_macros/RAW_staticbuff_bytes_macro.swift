// LICENSE MIT
// copyright (c) tanner silva 2024. all rights reserved.

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

fileprivate let domain = "RAW_staticbuff_macro"

/// thrown when a stored variable gets attached to a static buffer macro.
fileprivate struct StoredVariablesUnsupported:Swift.Error, DiagnosticMessage {
	public var message:String { "stored variables not supported in this mode. please add an accessor block or move this variable to a standalone extension." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_stored_variables_unsupported")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

/// thrown when a user attempts to use a tuple pattern binding for variables instead of a single identifier pattern.
fileprivate struct TuplePatternBindingsUnsupported:Swift.Error, DiagnosticMessage {
	public var message:String { "tuple pattern bindings not supported in this mode. please modify this variable expression to only use a single IdentifierPattern for its name" }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_tuple_pattern_bindings_unsupported")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

fileprivate struct VariableInitializationUnsupported:Swift.Error, DiagnosticMessage {
	public var message:String { "variable initialization not supported in this mode. please modify this variable expression to not have an initializer." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_variable_initialization_unsupported")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

fileprivate struct UnexpectedVariableType:Swift.Error, DiagnosticMessage {
	/// the type that was expected to be found on the given variable 
	public let expectedType:TokenSyntax
	/// the variable that was actually found
	public let foundType:TokenSyntax?
	public var message:String { "unexpected variable type declaration found. expected to find variable of type \(expectedType) but instad found type \(String(describing:foundType))" }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_missing_type_annotation")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

/// thrown when there is an extraneous variable declaration in the member body that is not expected.
fileprivate struct ExtraneousVariableDeclaration:Swift.Error, DiagnosticMessage {
	public var message:String { "extraneous variable declaration found. please move this variable to a standalone extension." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_extraneous_variable_declaration")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

fileprivate struct UnimplementedVariableMember:Swift.Error, DiagnosticMessage {
	public var message:String { "this member is not implemented in the attached body. please implement this variable in the body to silence this error." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_unimplemented_member")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

fileprivate struct LetBindingSpecifierUnsupported:Swift.Error, DiagnosticMessage {
	public var message:String { "let binding specifiers are not supported in this mode. please remove the let binding specifier from this variable declaration, and replace it with 'var'." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_let_binding_specifier_unsupported")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

fileprivate struct StructMustBeSendable:Swift.Error, DiagnosticMessage {
	public var message:String { "the attached struct must be marked as Sendable to use this macro." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_struct_must_be_sendable")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

fileprivate struct InvalidByteCount:Swift.Error, DiagnosticMessage {
	public var message:String { "the byte count must be a positive (or zero) integer literal." }
	public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_invalid_byte_count")}
	public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
}

fileprivate struct InvalidRAW_compareOverride {
	fileprivate struct MissingStaticModifier:Swift.Error, DiagnosticMessage {
		public var message:String { "expected to find a static modifier on the compare function override, but none was found." }
		public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_compare_missing_static_modifier")}
		public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
	}
	fileprivate struct InvalidRAW_comparable_fixedFunction:Swift.Error, DiagnosticMessage {
		public var message:String { "expected to find a function with the signature `static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32` but found a function with a different signature." }
		public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_compare_invalid_signature")}
		public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
	}
	fileprivate struct IncorrectAccessLevel:Swift.Error, DiagnosticMessage {
		public var message:String { "expected to find a function with the signature `static func RAW_compare(lhs_data:UnsafeRawPointer, rhs_data:UnsafeRawPointer) -> Int32` but found a function with a different signature." }
		public var diagnosticID:SwiftDiagnostics.MessageID { MessageID(domain:"RAW_macros", id:"staticbuff_compare_invalid_signature")}
		public var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
	}
}

public struct RAW_staticbuff_bytes_macro:MemberMacro, ExtensionMacro {
	private class NodeUsabeParser:SyntaxVisitor {
		internal var numberOfBytes:Int? = nil
		override func visit(_ node:IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
			numberOfBytes = Int(node.literal.text)!
			return .skipChildren
		}
	}

	public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		guard declaration.is(StructDeclSyntax.self) else {
			return []
		}

		if isMarkedSendable(declaration.as(StructDeclSyntax.self)!) == false {
			// a diagnostic will be thrown here by the attached member macro. in this condition, adding the extension would only cause more errors, so we do nothing to avoid confusion to the end developer.
			return []
		}

		// determine how many bytes this macro is to be used for.
		let nodeConfig = NodeUsabeParser(viewMode: .sourceAccurate)
		nodeConfig.walk(node)
		guard let byteCount = nodeConfig.numberOfBytes else {
			return []
		}
		guard byteCount >= 0 else {
			context.addDiagnostics(from:InvalidByteCount(), node:node)
			return []
		}

		return [try ExtensionDeclSyntax("""
			extension \(type):RAW_staticbuff {}
		""")]
	}

	public static func expansion(of node:SwiftSyntax.AttributeSyntax, providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
		// parse for the attached declaration
		let structFinder = StructFinder(viewMode: .sourceAccurate)
		structFinder.walk(declaration)
		guard let asStruct = structFinder.structDecl else {
			context.addDiagnostics(from:ExpectedStructAttachment(found:declaration.syntaxNodeType), node:node)
			return []
		}

		// parse for the sendable protocol conformance
		var foundInheritanceClause:InheritanceClauseSyntax? = nil
		guard isMarkedSendable(asStruct, withInheritanceClause:&foundInheritanceClause) else {
			var attachSyntax:SyntaxProtocol? = foundInheritanceClause
			if attachSyntax == nil {
				attachSyntax = asStruct
			}
			context.addDiagnostics(from:StructMustBeSendable(), node:attachSyntax!)
			return []
		}

		// determine how many bytes this macro is to be used for.
		let nodeConfig = NodeUsabeParser(viewMode: .sourceAccurate)
		nodeConfig.walk(node)
		guard let byteCount = nodeConfig.numberOfBytes else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("could not parse macro usage.")
			#endif
			return []
		}
		guard byteCount >= 0 else {
			#if RAWDOG_MACRO_LOG
			mainLogger.error("byte count must be greater than 0.")
			#endif
			context.addDiagnostics(from:InvalidByteCount(), node:node)
			return []
		}

		// find the RAW_compare functions in the struct. it may be overridden, but is not required to be.
		let compareFinder = FunctionFinder(viewMode:.sourceAccurate)
		compareFinder.validMatches.update(with:"RAW_compare")
		compareFinder.walk(asStruct)
		for foundFunc in compareFinder.funcDecl {

			#if RAWDOG_MACRO_LOG
			mainLogger.info("found RAW_compare override in struct declaration. validating format and naming...")
			#endif

			// check for the static modifier
			let staticFinder = StaticModifierFinder(viewMode:.sourceAccurate)
			staticFinder.walk(foundFunc)
			if staticFinder.foundStaticModifier == nil {
				#if RAWDOG_MACRO_LOG
				mainLogger.error("static modifier not found on compare function. this function will be skipped.")
				#endif
				context.addDiagnostics(from:InvalidRAW_compareOverride.MissingStaticModifier(), node:foundFunc)
				continue
			}

			var fparams = FunctionParameterLister(viewMode:.sourceAccurate)
			fparams.walk(foundFunc)
			guard fparams.parameters.count == 2, fparams.parameters[0].firstName.text == "lhs_data", let idL = fparams.parameters[0].type.as(IdentifierTypeSyntax.self), let idR = fparams.parameters[1].type.as(IdentifierTypeSyntax.self), fparams.parameters[1].firstName.text == "rhs_data" && idL.name.text == "UnsafeRawPointer" && idR.name.text == "UnsafeRawPointer" else {
				#if RAWDOG_MACRO_LOG
				mainLogger.error("expected exactly one parameter in compare function, found \(fparams.parameters.count)")
				#endif
				context.addDiagnostics(from:InvalidRAW_compareOverride.InvalidRAW_comparable_fixedFunction(), node:foundFunc)
				continue
			}

			let returnClauseFinder = ReturnClauseFinder(viewMode:.sourceAccurate)
			returnClauseFinder.walk(foundFunc)
			guard returnClauseFinder.returnClause?.type.as(IdentifierTypeSyntax.self)?.name.text == "Int32" else {
				#if RAWDOG_MACRO_LOG
				mainLogger.error("expected return type of Int32, found \(returnClauseFinder.returnClause?.type)")
				#endif
				context.addDiagnostics(from:InvalidRAW_compareOverride.InvalidRAW_comparable_fixedFunction(), node:foundFunc)
				continue
			}

			let effectSpecifier = FunctionEffectSpecifiersFinder(viewMode:.sourceAccurate)
			effectSpecifier.walk(foundFunc)
			guard effectSpecifier.effectSpecifier == nil || (effectSpecifier.effectSpecifier!.throwsClause?.throwsSpecifier == nil && effectSpecifier.effectSpecifier!.asyncSpecifier == nil) else {
				#if RAWDOG_MACRO_LOG
				mainLogger.error("expected no effect specifier on compare function, found \(effectSpecifier.effectSpecifier)")
				#endif
				context.addDiagnostics(from:InvalidRAW_compareOverride.InvalidRAW_comparable_fixedFunction(), node:foundFunc)
				continue
			}
		}

		var declString = [DeclSyntax]()
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
		let varScanner = VariableDeclLister(viewMode:.sourceAccurate)
		varScanner.walk(asStruct)
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

		declString.append(DeclSyntax("""
			/// initialize the static buffer from its raw representation store type. behavior is undefined if the raw representation is shorter than the assumed size of the static buffer.
			\(asStruct.modifiers) init(RAW_staticbuff storetype:consuming RAW_staticbuff_storetype) {
				#if DEBUG
				assert(MemoryLayout<Self>.size == MemoryLayout<RAW_staticbuff_storetype>.size, "static buffer type size mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Self>.stride == MemoryLayout<RAW_staticbuff_storetype>.stride, "static buffer type stride mismatch. this is a misuse of the macro")
				assert(MemoryLayout<Self>.alignment == MemoryLayout<RAW_staticbuff_storetype>.alignment, "static buffer type alignment mismatch. this is a misuse of the macro")
				#endif
				\(varName) = storetype
			}
		"""))

		declString.append(DeclSyntax("""
			/// borrow the raw representation of the static buffer.
			\(asStruct.modifiers) consuming func RAW_staticbuff() -> RAW_staticbuff_storetype {
				return \(varName)
			}
		"""))

		declString.append(DeclSyntax("""
			/// compare two instances of the same type.
			\(asStruct.modifiers) static func RAW_staticbuff_zeroed() -> RAW_staticbuff_storetype {
				return \(raw:generateZeroLiteralExpression(byteCount:UInt16(byteCount)))
			}
		"""))

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
			\(asStruct.modifiers) borrowing func RAW_encode(count: inout size_t) {
				count += MemoryLayout<RAW_staticbuff_storetype>.size
			}
		"""))
		declString.append(DeclSyntax("""
			@discardableResult \(asStruct.modifiers) borrowing func RAW_encode(dest:UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8> {
				withUnsafePointer(to:self) { buff in
					_ = RAW_memcpy(dest, buff, MemoryLayout<RAW_staticbuff_storetype>.size)!
				}
				return dest.advanced(by:MemoryLayout<RAW_staticbuff_storetype>.size)
			}
		"""))
		declString.append(DeclSyntax("""
			\(asStruct.modifiers) borrowing func RAW_access<R, E>(_ body: (UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E:Swift.Error {
				return try withUnsafePointer(to:self) { (buff:UnsafePointer<Self>) throws(E) -> R in
					let asBuffer = UnsafeBufferPointer<UInt8>(start:UnsafeRawPointer(buff).assumingMemoryBound(to:UInt8.self), count:MemoryLayout<RAW_staticbuff_storetype>.size)
					return try body(asBuffer)
				}
			}
		"""))
		declString.append(DeclSyntax("""
			\(asStruct.modifiers) borrowing func RAW_access_staticbuff<R, E>(_ body:(UnsafeRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
				return try withUnsafePointer(to:self) { (buff:UnsafePointer<Self>) throws(E) -> R in
					return try body(buff)
				}
			}
		"""))
		declString.append(DeclSyntax("""
			\(asStruct.modifiers) mutating func RAW_access_staticbuff_mutating<R, E>(_ body:(UnsafeMutableRawPointer) throws(E) -> R) throws(E) -> R where E:Swift.Error {
				return try withUnsafeMutablePointer(to:&self) { (buff:UnsafeMutablePointer<Self>) throws(E) -> R in
					return try body(UnsafeMutableRawPointer(buff))
				}
			}
		"""))
		
		return declString
	}
}