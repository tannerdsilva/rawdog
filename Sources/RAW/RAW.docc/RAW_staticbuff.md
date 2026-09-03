# ``RAW/RAW_staticbuff``

## Overview

`RAW_staticbuff` is the central conformance of the rawdog package. a type that
conforms to it is backed by **statically allocated storage** whose byte size is known
at compile time, and it inherits the whole rawdog stack:

- ``RAW_fixed`` — compile-time size via the `RAW_fixed_type` associated type
- ``RAW_comparable_fixed`` — fixed-size raw comparison
- `Sendable` — rawdog storage types are value types with no shared mutable state

the most common way to adopt `RAW_staticbuff` is the `@RAW_staticbuff(bytes:)` macro:

```swift
@RAW_staticbuff(bytes: 4)
struct FourBytes: RAW_staticbuff {}

MemoryLayout<FourBytes.RAW_fixed_type>.size // 4
```

applying `@RAW_staticbuff(bytes:)` attaches, in one step, the `RAW_staticbuff`,
``RAW_fixed``, ``RAW_accessible``, ``RAW_decodable``, ``RAW_encodable``,
``RAW_comparable``, and ``RAW_comparable_fixed`` conformances, lays out the storage as
a byte tuple of the requested size, and generates the decode, encode, and access
bodies.

## size composition

storage can also be built by concatenating other staticbuff types with
`@RAW_staticbuff(concat:)`:

```swift
@RAW_staticbuff(bytes: 2)
struct Header: RAW_staticbuff {}

@RAW_staticbuff(bytes: 6)
struct Payload: RAW_staticbuff {}

@RAW_staticbuff(concat: Header.self, Payload.self)
struct Packet: RAW_staticbuff {}
```

the composite's size is the sum of its parts. this mirrors the ``RAW_fixed``
composition story, but brings the full conformance stack along with it.

## seeking initialization

a `RAW_staticbuff` value can be loaded from a forward-seeking pointer. the pointer is
advanced by the type's size after initialization:

```swift
var ptr: UnsafeRawPointer = ...
let header = Header(RAW_staticbuff_seeking: &ptr)
// ptr now points just past the decoded value
```

## comparison and bitwise operators

because `RAW_staticbuff` refines ``RAW_comparable_fixed``, conforming types compare by
their raw byte representation lexicographically. types that also conform to
``RAW_accessible_mutable`` gain a bitwise complement operator:

```swift
let a = FourBytes(...)
let b = FourBytes(...)
a == b          // byte-wise equality
a < b           // lexicographic byte comparison
let flipped = ~a
```

## See Also

- <doc:RAW_fixed>
- <doc:RAW_accessible_immutable>
- ``RAW_accessible_mutable``
- <doc:RAW_decodable>
- <doc:RAW_encodable>
