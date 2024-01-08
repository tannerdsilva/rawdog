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