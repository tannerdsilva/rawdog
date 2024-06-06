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