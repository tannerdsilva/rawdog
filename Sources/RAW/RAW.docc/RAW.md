# ``RAW``

rawdog is a lean, dependency-free Swift package for compile-time-sized binary encoding and decoding.

the `RAW` module provides the core of the package: protocols and macros that express
**statically allocated memory** while automatically handling alignment, endianness,
and initialization to and from other types. in c, this is the `uint8_t[1024]` idiom; in
swift, rawdog restores that expressiveness with strict type safety and no runtime
overhead.

at a glance:

- ``RAW_staticbuff`` — the central conformance, backed by compile-time-sized storage
- ``RAW_fixed`` — compile-time size expressed through an associated type
- ``RAW_accessible_immutable`` / ``RAW_accessible_mutable`` — safe, closure-scoped raw
  memory access
- ``RAW_decodable`` / ``RAW_encodable`` — raw binary decode and encode with an atomic
  consumption contract
- ``RAW_native`` — explicit encodings of native Swift types (ints, floats, strings)
- ``RAW_hasher`` — a common interface for the hashing algorithms in the companion
  `RAW_sha1`–`RAW_blake2` modules
- secure memory utilities: ``secureZeroBytes(_:count:)`` and
  ``generateSecureRandomBytes(count:)``
- ``MemoryGuarded`` — page-locked, zeroing storage for sensitive values

## Topics

### articles

- <doc:RAW_staticbuff>
- <doc:RAW_fixed>
- <doc:RAW_accessible_immutable>
- ``RAW_accessible_mutable``
- <doc:RAW_decodable>
- <doc:RAW_encodable>
- <doc:RAW_convertible>

### protocols

- ``RAW_staticbuff``
- ``RAW_fixed``
- ``RAW_accessible_immutable``
- ``RAW_accessible_mutable``
- ``RAW_decodable``
- ``RAW_encodable``
- ``RAW_native``
- ``RAW_encoded_fixedwidthinteger``
- ``RAW_encoded_binaryfloatingpoint``
- ``RAW_encoded_unicode``
- ``RAW_hasher``
- ``RAW_comparable``
- ``RAW_comparable_fixed``

### type aliases

- ``RAW_accessible``

### types

- ``RAW_byte``
- ``MemoryGuarded``
- ``RAW_encoded_unicode_iterator``

### functions

- ``secureZeroBytes(_:count:)``
- ``generateSecureRandomBytes(count:)``
- ``RAW_memcpy(_:_:_:)``

### macros

- ``RAW_staticbuff(bytes:)``
- ``RAW_staticbuff(concat:)``
- ``RAW_staticbuff_init(_:RAW_decode:storage:)``
- ``RAW_staticbuff_access(_:storage:bodyReturnType:bodyThrowsType:body:)``
- ``RAW_staticbuff_access_mutating(_:storage:bodyReturnType:bodyThrowsType:body:)``
- ``RAW_staticbuff_encode_count(RAW_fixed:)``
- ``RAW_accessible_encode(_:destination:)``
- ``RAW_fixed(bytes:)``
- ``RAW_fixed(concat:)``
- ``RAW_fixed_type(bytes:)``
- ``RAW_fixed_type(concat:)``
- ``RAW_decode_decl(RAW_staticbuff:storage:)``
- ``RAW_decode_impl(RAW_staticbuff:storage:)``
- ``RAW_encode_decl(RAW_staticbuff:storage:)``
- ``RAW_encode_impl(RAW_staticbuff:storage:)``
- ``RAW_encode_count_impl(RAW_fixed:)``
- ``RAW_access_immutable_decl(RAW_staticbuff:storage:)``
- ``RAW_access_immutable_impl(RAW_staticbuff:storage:)``
- ``RAW_access_mutable_decl(RAW_staticbuff:storage:)``
- ``RAW_access_mutable_impl(RAW_staticbuff:storage:)``
- ``RAW_staticbuff_fixedwidthinteger_type(bigEndian:)``
- ``RAW_staticbuff_binaryfloatingpoint_type()``
- ``RAW_convertible_string_type(backing:)``
