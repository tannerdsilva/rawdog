# ``RAW/RAW_fixed``

## Overview

`RAW_fixed` identifies types whose memory size is known at compile time. size is
expressed through the `RAW_fixed_type` associated type rather than a runtime property,
so rawdog can reason about memory layout statically: no dynamic size calculations, no
runtime storage allocation, no overhead.

```swift
public protocol RAW_fixed {
    associatedtype RAW_fixed_type
}
```

the size of a conforming instance is

```swift
MemoryLayout<Conformer.RAW_fixed_type>.size
```

`RAW_fixed` is the foundation that ``RAW_staticbuff`` builds on. the protocol itself
only concerns itself with total size; stride and alignment are not part of its
contract. in practice `RAW_fixed_type` is almost always a tuple of bytes, or a tuple of
individual types that themselves conform to `RAW_fixed`, which lets complex structures
compose from fixed-size primitives.

## adoption with macros

### RAW_fixed(bytes:)

the attached extension macro `@RAW_fixed(bytes:)` conforms the annotated type to
`RAW_fixed` and declares `RAW_fixed_type` as a byte tuple of the given size:

```swift
@RAW_fixed(bytes: 16)
struct Block {}

MemoryLayout<Block.RAW_fixed_type>.size  // 16
```

### RAW_fixed_type(bytes:)

the freestanding declaration macro `#RAW_fixed_type(bytes:)` declares the same byte
tuple directly inside a type body, when the conformance is written by hand:

```swift
struct Block: RAW_fixed {
    #RAW_fixed_type(bytes: 16)
}
```

### RAW_fixed(concat:)

the attached extension macro `@RAW_fixed(concat:)` declares `RAW_fixed_type` as the
concatenation of other fixed types:

```swift
struct Header: RAW_fixed {
    #RAW_fixed_type(bytes: 4)
}

struct Payload: RAW_fixed {
    #RAW_fixed_type(bytes: 64)
}

@RAW_fixed(concat: Header.self, Payload.self)
struct Packet {}
```

the composite size is `4 + 64 = 68` bytes. the freestanding
`#RAW_fixed_type(concat:)` form is available for hand-written conformances.

## See Also

- <doc:RAW_staticbuff>
- <doc:RAW_accessible_immutable>
- ``RAW_accessible_mutable``
- <doc:RAW_decodable>
