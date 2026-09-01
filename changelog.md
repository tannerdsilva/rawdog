# 22.0.0

- Complete macro/protocol rework of the fixed-length data model (the `v22-rewrite` line). A detailed v21→v22 migration map lives in the rawdog skills reference (`swift-cross-package-verification` → `references/rawdog-v22-api-migration.md`).

- `RAW_fixed_type` is now the single canonical storage typealias, generated directly by the `@RAW_staticbuff` macro. The v21 `RAW_staticbuff_storetype` name is preserved as a deprecated alias on `extension RAW_fixed` (with a rename fix-it). v21 `public typealias RAW_fixed_type = RAW_staticbuff_storetype` declarations must be deleted — the macro generates the typealias itself, so the redeclaration self-references.

- Native-type macros retain their v21 form (`@RAW_staticbuff_fixedwidthinteger_type<T>(bigEndian:)`, `@RAW_staticbuff_binaryfloatingpoint_type<T>()`) and now auto-inject the `RAW_encoded_fixedwidthinteger` / `RAW_encoded_binaryfloatingpoint` conformance. The freestanding `#`-form used briefly mid-rewrite has been removed.

- `@RAW_staticbuff(bytes:)` generates its storage and member surface; the lower-level pieces are exposed as standalone macros for hand-written types:

	- `#RAW_fixed_type(bytes:)` / `#RAW_fixed_type(concat:)` for the storage typealias.
	- `#RAW_staticbuff_init`, `#RAW_staticbuff_access(_:storage:bodyReturnType:bodyThrowsType:body:)`, `#RAW_decode_decl`/`_impl`, `#RAW_encode_decl`/`_impl`, `#RAW_access_immutable_decl`/`_impl`, `#RAW_access_mutable_decl`/`_impl`.
	- Stored instance properties are rejected by default (only `static` and computed properties are allowed).

- `@RAW_staticbuff(concat:)`:

	- Default mode: the storage is auto-generated as a `_bytes` member holding the concatenated component tuple.
	- v21 compatibility mode: exactly N stored instance properties typed as the N concat components (in order) are accepted as the payload — no `_bytes` member is generated, and all access/decode/encode/compare machinery resolves through protocol defaults. Any other stored properties still produce a diagnostic with fix-its.

- Access model: `RAW_accessible` is now the intersection of `RAW_accessible_immutable` and `RAW_accessible_mutable`, exposing `RAW_access_immutable(_:UnsafeRawBufferPointer.Type, _:)` and `RAW_access_mutable(_:UnsafeMutableRawBufferPointer.Type, _:)`. The v21 `RAW_access` / `RAW_access_mutating` names are retained as deprecated requirements with mutual defaults, so hand-written v21 conformances compile unchanged and drive the whole v22 accessor/encode surface through the witness table.

- Decode model: `init?(RAW_decode _:UnsafeRawBufferPointer)` is the canonical decoder. The v21 `init?(RAW_decode:UnsafeRawPointer, count:size_t)` remains a deprecated requirement with a default — both conformance styles and both call forms work.

- `RAW_staticbuff` now inherits `RAW_comparable_fixed`, providing `RAW_compare` plus `RAW_comparable_fixed_theoretical_min()` / `RAW_comparable_fixed_theoretical_max()` defaults over `MemoryLayout<RAW_fixed_type>`.

- All access/decode members use typed throws (`throws(E)`).

- `size_t` migrated to `Int` throughout the API (`RAW_encode(count:)`, error payloads, and so on — behavior-neutral, as C `size_t` imports as `Int`).

- `RAW_kdf` added as a published product; dead symbols dropped; ed25519 sign/verify buffers sized against the 64-byte signature contract.

- Migration for v21 macro-using consumers is a single mechanical edit: delete the redundant `typealias RAW_fixed_type = RAW_staticbuff_storetype`; everything else compiles with deprecation warnings + rename fix-its. Verified against pristine v21 bedrock (`da5b3d9`): clean build, 59 tests / 14 suites green after that one edit. Deliberately not bridged: `RAW_decodable_unbounded`, and concat types with stored state beyond the component set.

# 21.0.0

- Expanded the `curve25519` surface to full `ed25519` signatures, exposed through a new `RAW_ed25519` product:

	- `PrivateKey` (64-byte static buffer type).
	- Non-copyable `BlindingContext` for hardened signing operations, backed by native C context storage.
	- Reusable `VerificationContext` for verifying large volumes of messages.
	- `generateKeys(secretKey:)` top-level helper, using `RAW_dh25519` keys.

- `RAW_mnemonic` complete rework around a new 2048-word English wordlist: a `Mnemonic` type with BIP39-style entropy ↔ words conversion (16–32 bytes of entropy, SHA-256 checksum, 12–24 words), plus typed errors.

- `RAW_dh25519.PublicKey`: new `init(privateKey: MemoryGuarded<PrivateKey>)` (memory-guarded secret storage); the `UnsafePointer<PrivateKey>` variant is deprecated with a migration note.

- `RAW_comparable_fixed` adds `RAW_comparable_fixed_theoretical_max()` / `RAW_comparable_fixed_theoretical_min()` requirements, defaulted for `RAW_staticbuff` types.

- `RAW_base64` ergonomics: the `Error` type is extracted into its own file and is now `CustomDebugStringConvertible`; the `invalidEncodingLength` payload migrated from `size_t` to `Int`.

- `RAW_ed25519` and `RAW_mnemonic` registered as `.library` products in the package manifest; test harness coverage expanded for both.

## 20.1.0

- Added the `~` prefix operator to invert the bits of a `RAW_staticbuff` value (all `RAW_staticbuff` types).

# 20.0.0

- Introduction of a new reference type `MemoryGuarded<GuardedStaticbuffType> where GuardedStaticbuffType:RAW_staticbuff`

	- Used to store secure secrets. Implements memory page locking and zeroing to ensure the enclosed secrets are copied as few times as possible.

- `RAW_dh25519` target refactored to implement `MemoryGuarded` storage.

- Added initializer variant to `RAW_chachapoly.Context`: `public init?(key:UnsafeBufferPointer<UInt8>)`

- Now requires Swift 6.2

### 19.0.2

- Bugfix for `RAW_staticbuff_seeking` initializer.

### 19.0.1

- `RAW_byte` is now `ExpressibleByIntegerLiteral`.

# 19.0.0

- `public init(RAW_staticbuff_seeking storeVal:UnsafeMutablePointer<UnsafeRawPointer>)` replaces `public init(RAW_staticbuff_seeking storeVal:inout UnsafeRawPointer)`

# 18.0.0

- Added extension that allows `RAW_hasher` conformant types to update with `UnsafePointer<RAW_accessible>`.

- Modified `RAW_hasher` protocol to offer more complete coverage of functions that update with unsafe pointers of various types.

	- New required implementation: `RAW_hasher` requires `func finish(into _:UnsafeMutableRawPointer) throws`.

		- The existing `finish<S>(into:inout Optional<S>) where ...` requirement exists but now comes with a default implementation when the new finish function is implemented.

- Unit tests have been translated away from XCTest and now utilizes Swift's native `Testing` top-to-bottom.

- Significantly re-engineered testing strategy for `RAW_hmac`.

### 17.0.2

- Fixed bug where `generateSecureRandomBytes` function returned no/zeroed data instead of secure random bytes.

### 17.0.1

- `RAW_staticbuff(concat:)` macro now supports types that are nested within other types (for example, `MyTypeA.SomeInnerType.self`)

# 17.0.0

- Modified the function signature of `generateRandomBytes` variant that handles [UInt8] type. In prior versions, this function clashed with other variants that made it difficult to access both symbols reliably.   

# 16.0.0

- Revised syntax requirements for macro usage.

	Previous syntax usage guidelines for this library failed to translate into Swift 6.1 without causing errors. This release is mostly focused on restoring the macro functionality for Swift 6 and beyond.

	- Improved macro usage diagnostics.

		- Significant focus given to how macros behave with incomplete or invalid syntax.

		- Fix-It diagnostics are now provided for a majority of macro errors.
		
# 15.0.0

- Revised and improved Swift 6 implementation.

# 14.0.0

- Swift 6.

- Strict typing for all throwing functions, including nested blocks within functions.

- No longer using `rethrows` syntax anywhere.

### 13.0.3

- Insignificant internal changes.

### 13.0.2

- Added more variants of the secure zeroing implementation found in `RAW` target.

### 13.0.1

- Fixed bug with xcode building.

# 13.0.0
	
- Major releases going forward will do a better job at directly documenting breaking API changes.

- Introduction of RAW_hasher protocol for hashing agnostic HMAC.

- Breaking API changes in this release (compared to prior):

	- Public API for hashing targets modified (mostly to align with RAW_hasher protocol).
	
	- Macro-free `RAW_staticbuff`s will find new function requirements to implement.

- Other changes include:

	- `RAW_blake2\Hasher` now supports `UnsafeMutableRawPointer` as an output type.

	- `RAW_byte` convenience type now conforms to more protocols.

	- Large array of new cryptography functions added (with tests).
		
		- Notably: argon2 hashing / kdf!

## 12.1.0

- rawdog source code now includes a powerful and complete suite of cryptographic source material. README.md outlines the cryptography included and the original sources for all functions, which are heavily modified in a multitude of ways.

	- These cryptographic tools will become available with their own targets in future minor releases.
	
	- This release of rawdog is packaged with the first target amongst these new tools: blowfish password hashing in the `RAW_bcrypt_blowfish` target.
	
		- bcrypt blowfish is known best as a strong password hashing algorithm that is particularly difficult to brute force.

# 12.0.0

- Revised public API of Blake2 hashing initializers when output type is a RAW_staticbuff compliant type.

# 11.0.0

- `RAW_staticbuff` protocol now requires Sendable. This cannot be implemented behind the scenes with the core macro, however, the macro has been updated to make the new requirement clear to users.

## 10.1.0

- `RAW_staticbuff` macro now allows users to define or override the default logic for `RAW_comparable_fixed`, which was previously implemented blindly by the macro or extensions depending on the configuration of the macro.

	- Macro includes 3 helpful diagnostic messages that can be thrown in this context to help the user understand what to do when trying to override the comparison logic.

# 10.0.0

- Introduced pointer-less functions into `RAW_staticbuff`.

	- Pointer-free initializer with a consuming `RAW_staticbuff_storetype` argument.

	- Pointer-free self-consuming function that returns `RAW_staticbuff_storetype`.

- `RAW_comparable_fixed` protocol now includes `RAW_comparable`.

# 9.0.0

- Reintroduction of mutating access functions into the `RAW_accessible` and `RAW_staticbuff` protocols.

## 8.1.0

- Created `RAW_byte` struct to allow for convenient and consistent byte applications across applications.

### 8.0.1

- Allow `let` binding specifier for member variables of RAW_staticbuff macro.

# 8.0.0

- Changed keyed initializer functions offered by extension on ``RAW_blake2\Hasher``, these key arguments now accept any `RAW_accessible`. Now has a slightly less confusing public API on paper.

- Simplified & reduced clutter on the public API surface for `RAW_base64` and `RAW_hex`.

## 7.1.0

- Revised string macro implementation with better informed encode/decode implementation (through internal sequence implementations).

	- Copies have been better optimized with borrow/consume.

	- String types created with the `RAW_convertible_string_type` are now better adherent to `Sequence` protocol in that they take O(1) time to `makeIterator()`.

### 7.0.1

- Default array extensions are now borrowing.

# 7.0.0

- Re-imagined memory paradigm with Swift 5.9 in mind. Swift 5.9 has been a requirement of this library since version 6.x.x, so optimizing the library around these newer memory contepts are yielding much better performance.

	- Mutating memory concepts have been fully deleted from the project. 
	
		- Applying mutations to existing regions of memory was never a primary focus of this library.
			
			- Existing API for mutating data was far from flexible enough in v6, and also required mutability in contexts where it ideally wouldn't be needed.
			
			- Now with borrowing/consuming, there are better ways of providing direct access to memory without having to hack mutability into the project.

		- In its place, zero-copy memory is guranteed by way of the new `borrowing` and `consuming` keywords in Swift.

### 6.2.10

- Updated `RAW_staticbuff` macro to allow extraneous variables that are computed and/or static. 

### 6.2.9

- Removes the only declaration from the CRAW header (and its underlying implementation in the `.c` file). `CRAW` is now header-only.

### 6.2.8

- Removes `RAWDOG_MACRO_LOG` from default package configuration.

### 6.2.7

- ``RAW_staticbuff`` validation no longer seeks within codeblocks

### 6.2.6

- Added additional conformances to native `[UInt8]` type. In addition to the previous conformances (`RAW_encodable` and `RAW_accessible`), it now conforms to `RAW_comparable` and `RAW_decodable` by default.

### 6.2.5

- Blake2 hasher can now update with any `RAW_accessible` (including `[UInt8]` which is conformant by default) instead of strictly `[UInt8]`.

### 6.2.4

- Fixed extraneous warning thrown from syntax output in ``RAW_encoded_unicode`` macro.

### 6.2.3

- Another small fix to an internal type that users should never need to interact with (internal changes, once again).

### 6.2.2

- Fixed bug where comments could leak into RAW_comparable macro output.

### 6.2.1

- Modified access level on a public type that users should never need to interact with (internal change).

## 6.2.0

- ``RAW_accessible`` types that are already ``RAW_comparable`` and proclaim ``Comparable`` or ``Equatable`` will receive automatic implementations that are backed by the ``RAW_comparable`` type.

- ``RAW_encoded_unicode`` requires and automatically implements ``Comparable`` and ``Equatable`` based on the underlying (existing) ``RAW_comparable`` conformance.

## 6.1.0

- Rolls back on prior release, as it was a completely ineffective change that yielded no discernable outcome.

- Modified RAW_native getter function (``RAW_native()``) to no longer be mutating.

### 6.0.2 (revoked - changes involving Sendable protocol were completely ineffective)

### 6.0.1

- ``RAW_staticbuff`` macro is now friendly to static variables in attached bodies and no longer marks these declarations as errors.

# 6.0.0

- Effectively rolls back the changes applied in v5.2.0 after a failed attempt to integrate with a downstream project (QuickLMDB, in this case). While it made sense at the time to separate the two distinct functions/roles behind ``RAW_accessible`` and ``RAW_encodable``, in reality, it is very tedious to try and efficiently develop against both of these protocols without some relationships being introduced into the landscape here.

	- ``RAW_accessible`` is inheritly ``RAW_encodable``, since its byte representation is already known in memory, it simply needs to be copied.

## 5.2.0

- Minor tweaks to protocol conformances regarding ``RAW_accessible`` and ``RAW_encodable``, specifically how these two nest and relate to each other.

	- Prior versions of this library had ``RAW_encodable`` as a required protocol to ``RAW_accessible``. This is no longer the case.
	
	- ``RAW_accessible`` and ``RAW_encodable`` are standalone protocols with no additional conformance requirements.

		- Both protocols offer default extensions that allow one to behave as the other.

			- ``RAW_accessible`` will use its existing bytes to implement ``RAW_encodable`` function names by default.

			- ``RAW_encodable`` will encode its contents into a standalone buffer for the accessor function.

		- Users can conform to both of these protocols to offer the most efficient implementations for both.

## 5.1.0

- Added extensions to ``UnsafeMutableBufferPointer<UInt8>`` allowing it to conform directly to ``RAW_accessible``.

# 5.0.0 'Mega Macro Makeover'

- Introduction of a new protocol ``RAW_fixed`` which provides many of the functions and utilities that ``RAW_staticbuff`` served in the `4.x.x` releases.

- Modified the design of the ``RAW_staticbuff`` protocol (and its macro) to optimally dovetail and operate with new sister protocol ``RAW_fixed``.

- Removed many default implementations on default types.

	- Native BinaryInteger types are no longer extended in this library. Use macros to enable this functionality on your own types.

	- Native BinaryFloatingPoint types are no longer extended in this library. These too are available with macros.

- Introduction of convenience protocols ``RAW_convertible_fixed`` and ``RAW_comparable_fixed``, allowing users to build static-length binary types with minimal implementation overhead.

	- As such, ``RAW_staticbuff`` has dropped its explicit requirements for length-static comparisons, and simply adds this ``RAW_comparable_fixed`` as a required conformance.
	
- Introduction of two new macros that provide the functionality that the default extensions (on native types) used to provide.

	- ``RAW_staticbuff_fixedwidthinteger_type`` transforms the attached struct to a static buffer type that contains encoded data for integers.

	- ``RAW_staticbuff_binaryfloatingpoint_type`` transforms the attached struct to a static buffer type that contains the encoded data for floating point values.
	
- Improved flexability and diagnostic capabilities of all builtin macros, making them easier and less fussy in use.

- Removed built-in ``RAW_convertible_fixed`` implementations for numerical types in ``RAW`` target. Users are expected to express their implementations directly in their projects as explicit struct trypes using ``@RAW_staticbuff...`` macros.

### 4.3.4

- Expanded platform support on MacOS, from v11 to v10.15.

### 4.3.3

- Modified ``RAW_staticbuff`` initializer extension ``RAW_staticbuff_storetype_seeking`` to use `inout` argument type.

### 4.3.2

- Modified ``public static func RAW_compare(...seeking:...)`` variants to use inout argument types.

	- This change fixed an underlying bug in the previous implementation of this function. This bug is now fixed.

- Added tests that prove `ConcatBufferTypeMacro` is implementing linear comparisons as expected.

# v4.x.x

- Continued iteration of the library - another breaking update that brings improvements that are worth the hastle.

- Introduction of new `RAW_encodable` and `RAW_decodable` protocols that operate efficiently and tightly with low-level memory.

- Introduction of macros that make it easy and convenient to build primitive, binary-based data types in Swift.

# v3.0.0

- Major rearchitecture and reorganization of the fundamental protocols and their relationships.

- Bumps Swift version requirement to 5.9 or above.

	- Enables the first of many macros that will allow for effortless creation of primitive, low-level data types.

		- The first of these being ``StaticBufferType`` macro, which attaches to a class or struct declaration.

- Implemented some tests.

- Built-in base64 encoding and decoding.

# v2.0.0

- Changed encoding and decoding protocols to be based on `(size_t, UnsafeMutableRawPointer)` signatures instead of `(RAW_val)`.

- Made `RAW_comparable` more Swift friendly.

## v1.1.0

- Added additional comments to various protocol implementations to `RAW_val`.

- `RAW_val` now conforms to `Collection` protocol, as well as the `Sequence` protocol.

- Introduction of this document, `changelog.md`.

# v1.0.0

Initial release.