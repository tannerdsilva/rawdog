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