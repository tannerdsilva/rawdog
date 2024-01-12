# 5.0.0

- Introduction of a new protocol ``RAW_fixed`` which provides many of the functions and utilities that ``RAW_staticbuff`` served in the `4.x.x` releases.

- Modified the design of the ``RAW_staticbuff`` protocol (and its macro) to optimally dovetail and operate with new sister protocol ``RAW_fixed``.

- Modified default protocols implemented on native numerical types

	- BinaryInteger types are now ``RAW_fixed``, since they no longer meet the requirements to be fully compliant with ``RAW_staticbuff``.
	
		- BinaryInteger is not guaranteed to be endian corrects, so while they are convertible with fixed assumptions, they cannot be blindly copied directly off of memory with any guaranteed durability, hence, why they cannot be ``RAW_staticbuff`` compliant.

- Introduction of convenience protocols ``RAW_convertible_fixed`` and ``RAW_comparable_fixed``, allowing users to build static-length binary types with minimal implementation overhead.

	- As such, ``RAW_staticbuff`` has dropped its explicit requirements for length-static comparisons, and simply adds this ``RAW_comparable_fixed`` as a required conformance.
	
- Introduction of ``@RAW_staticbuff_fixedwidthinteger_type`` (attached member) and ``#RAW_staticbuff_fixedwidthinteger_init`` (freestanding declaration) macros. These macros automatically implement big or little endian encodings into a attached struct, and 

	- These macros can help developers regain the functionality lost by the dropping of ``RAW_staticbuff`` on native integer types from 4.x.x.
	
- Improved flexability and diagnostic capabilities of all builtin macros, making them easier and less fussy in use.



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