# ``RAW/RAW_accessible_mutable``

## Overview

`RAW_accessible_mutable` extends ``RAW_accessible_immutable`` with **mutating** access
to a type's raw storage. immutable access is enough for reading and encoding; in-place
decryption, checksum updates, and direct memory manipulation require write access.

like its immutable counterpart, access is closure-scoped: the receiver's storage is
handed to the closure as an `UnsafeMutableRawBufferPointer` that cannot escape.

the protocol refines ``RAW_accessible_immutable``, so any conforming type supports both
reading and writing. it carries a single requirement — ``RAW_access_mutable(_:_:)`` —
passed an `UnsafeMutableRawBufferPointer`. the deprecated v21 name
``RAW_access_mutating(_:)`` is preserved as a deprecated forwarding convenience so v21
call sites keep compiling; it dispatches through the witness table to the conformer's
`RAW_access_mutable(_:_:)` member.

## requirements

```swift
public protocol RAW_accessible_mutable: RAW_accessible_immutable {
    mutating func RAW_access_mutable<R, E>(
        _: UnsafeMutableRawBufferPointer.Type,
        _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R
    ) throws(E) -> R where E: Swift.Error
}
```

- `mutating` signals that the accessor may modify the underlying storage.
- the `UnsafeMutableRawBufferPointer.Type` first argument is the typed sentinel that
  disambiguates the raw-buffer accessor from its byte-typed and untyped conveniences.
- `throws(E)` keeps Swift typed throws intact through mutable access.

## byte-typed conveniences

the common byte-level case is covered by a convenience that re-exposes the mutable raw
buffer as an `UnsafeMutableBufferPointer<UInt8>`:

```swift
var bytes: [UInt8] = [0x00, 0x01, 0x02]
bytes.RAW_access_mutable(UnsafeMutableBufferPointer<UInt8>.self) { buffer in
    buffer[0] = 0xFF
}
```

when the closure parameter type is unambiguous, even the sentinel can be omitted:

```swift
bytes.RAW_access_mutable { (buffer: UnsafeMutableBufferPointer<UInt8>) in
    buffer[0] = 0xFF
}
```

`Array<UInt8>` conforms to `RAW_accessible_mutable`, so this works out of the box.

## adoption for RAW_staticbuff types

types declared with `@RAW_staticbuff(bytes:)` gain `RAW_accessible_mutable`
automatically — the macro generates the storage accessors.

for hand-written storage, the macro pair
``RAW_access_mutable_decl(RAW_staticbuff:storage:)`` and
``RAW_access_mutable_impl(RAW_staticbuff:storage:)`` generate the required signature
and body against a key path into the type's storage:

```swift
struct MyData: RAW_accessible_mutable {
    var storage: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0)

    RAW_access_mutable_decl(
        RAW_staticbuff: MyData.self,
        storage: \.storage
    )

    mutating func RAW_access_mutable<R, E>(
        _: UnsafeMutableRawBufferPointer.Type,
        _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R
    ) throws(E) -> R where E: Swift.Error {
        RAW_access_mutable_impl(
            RAW_staticbuff: MyData.self,
            storage: \.storage
        )
    }
}

var data = MyData()
try data.RAW_access_mutable { buffer in
    buffer[0] = 0xAA
}
```

the generated body hands the closure an `UnsafeMutableRawBufferPointer` over the
referenced storage, preserving alignment and the closure-scoped safety guarantee.

## safety

- **exclusive access** — while the body closure runs, the storage is exclusively
  borrowed; do not access the same memory from another thread or closure.
- **binding** — when assuming memory bound to a specific type inside the closure, the
  size and alignment must match the underlying storage.
- **initialization** — memory must be initialized before reading, even through a
  mutable accessor.

## See Also

- <doc:RAW_accessible_immutable>
- <doc:RAW_staticbuff>
- <doc:RAW_decodable>
- <doc:RAW_encodable>
