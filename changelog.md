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