# ``RAW/RAW_encodable``

## Overview

`RAW_encodable` is the encode-side counterpart to ``RAW_decodable``. conforming types
can write themselves to raw, durable memory storage, reporting either their encoded
size or writing directly to a destination pointer.

## requirements

```swift
public protocol RAW_encodable {
    borrowing func RAW_encode(count: inout Int)
    @discardableResult borrowing func RAW_encode(
        _: UnsafeMutableRawPointer.Type,
        destination: UnsafeMutableRawPointer
    ) -> UnsafeMutableRawPointer
}
```

- `RAW_encode(count:)` writes the encoded byte size of the value into the `inout Int`
  argument. this is used to size a destination buffer before encoding.
- `RAW_encode(_:destination:)` writes the value's raw bytes to the destination pointer
  and **returns the pointer advanced by exactly the number of bytes written**. a
  conformer that returns an incorrect advance breaks the ability to chain encodes
  back-to-back, so the returned advance must match the count reported by
  `RAW_encode(count:)`.

both requirements are `borrowing`, so encoding never copies or consumes the value.

## conveniences

for byte destinations, a typed convenience re-exposes the raw-pointer form through an
`UnsafeMutablePointer<UInt8>`:

```swift
let advanced = value.RAW_encode(
    UnsafeMutablePointer<UInt8>.self,
    destination: dest
)
```

and a second convenience omits the sentinel when the destination type is clear:

```swift
let advanced = value.RAW_encode(dest: dest) // dest: UnsafeMutablePointer<UInt8>
```

`Array<UInt8>` conforms to `RAW_encodable`, as does any ``RAW_accessible_immutable``
type that declares conformance.

## adoption for RAW_staticbuff types

### automatic via @RAW_staticbuff

types declared with `@RAW_staticbuff(bytes:)` gain `RAW_encodable` automatically — the
macro generates both requirements from the fixed storage layout.

### hand-written: the macro pair

for hand-written storage, ``RAW_encode_decl(RAW_staticbuff:storage:)`` and
``RAW_encode_impl(RAW_staticbuff:storage:)`` generate the signature and body against
a key path into the type's storage; ``RAW_encode_count_impl(RAW_fixed:)`` fills in
the `RAW_encode(count:)` body for any ``RAW_fixed`` type:

```swift
struct FixedSizeBlock: RAW_encodable {
    var storage: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0)

    RAW_encode_decl(
        RAW_staticbuff: FixedSizeBlock.self,
        storage: \.storage
    )

    borrowing func RAW_encode(
        _: UnsafeMutableRawPointer.Type,
        destination: UnsafeMutableRawPointer
    ) -> UnsafeMutableRawPointer {
        RAW_encode_impl(
            RAW_staticbuff: FixedSizeBlock.self,
            storage: \.storage
        )
    }

    borrowing func RAW_encode(count: inout Int) {
        RAW_encode_count_impl(RAW_fixed: FixedSizeBlock.self)
    }
}
```

## a complete encode pipeline

sizing, then writing, gives the full picture:

```swift
// 1. size the value
var size = 0
value.RAW_encode(count: &size)

// 2. allocate and write
var bytes = [UInt8](repeating: 0, count: size)
bytes.withUnsafeMutableBytes { raw in
    _ = value.RAW_encode(UnsafeMutableRawPointer.self, destination: raw.baseAddress!)
}
```

## See Also

- <doc:RAW_decodable>
- <doc:RAW_fixed>
- <doc:RAW_staticbuff>
- <doc:RAW_accessible_immutable>
