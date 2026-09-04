# ``RAW/RAW_accessible_immutable``

## Overview

`RAW_accessible_immutable` defines the contract for types that expose their underlying
raw storage for **immutable** access. rawdog types hold their bytes in statically
allocated storage; this protocol is how you read them.

access is **closure-scoped**: the receiver hands your closure an
`UnsafeRawBufferPointer` view of its storage, and the pointer cannot escape that scope.
this keeps rawdog memory-safe even while operating on raw bytes.

the protocol carries a single requirement — ``RAW_access_immutable(_:_:)`` — passed an
`UnsafeRawBufferPointer`. the deprecated v21 name ``RAW_access(_:)`` is preserved as a
deprecated forwarding convenience so v21 call sites keep compiling; it dispatches
through the witness table to the conformer's `RAW_access_immutable(_:_:)` member.

## requirements

```swift
public protocol RAW_accessible_immutable {
    borrowing func RAW_access_immutable<R, E>(
        _: UnsafeRawBufferPointer.Type,
        _ body: (UnsafeRawBufferPointer) throws(E) -> R
    ) throws(E) -> R where E: Swift.Error
}
```

- `borrowing` keeps the accessor copy-free without taking ownership.
- the `UnsafeRawBufferPointer.Type` first argument is a typed sentinel that
  disambiguates the raw-buffer accessor from its byte-typed and untyped conveniences.
- `throws(E)` is Swift typed throws: the exact error type `E` flows through the
  accessor, so error handling stays precise across the whole call.

## byte-typed conveniences

the common byte-level case is covered by a convenience that re-exposes the raw buffer
as an `UnsafeBufferPointer<UInt8>`:

```swift
let totalBytes = value.RAW_access_immutable(UnsafeBufferPointer<UInt8>.self) { bytes in
    bytes.count
}
```

when the closure parameter type is unambiguous, even the sentinel can be omitted:

```swift
let totalBytes: Int = value.RAW_access_immutable { (bytes: UnsafeBufferPointer<UInt8>) in
    bytes.count
}
```

## adoption for RAW_staticbuff types

types declared with `@RAW_staticbuff(bytes:)` gain `RAW_accessible_immutable`
automatically — the macro generates the storage accessors.

for hand-written storage, the macro pair
``RAW_access_immutable_decl(RAW_staticbuff:storage:)`` and
``RAW_access_immutable_impl(RAW_staticbuff:storage:)`` generate the required signature
and body against a key path into the type's storage:

```swift
struct MyData: RAW_accessible_immutable {
    var storage: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0)

    RAW_access_immutable_decl(
        RAW_staticbuff: MyData.self,
        storage: \.storage
    )

    borrowing func RAW_access_immutable<R, E>(
        _: UnsafeRawBufferPointer.Type,
        _ body: (UnsafeRawBufferPointer) throws(E) -> R
    ) throws(E) -> R where E: Swift.Error {
        RAW_access_immutable_impl(
            RAW_staticbuff: MyData.self,
            storage: \.storage
        )
    }
}
```

the generated body hands the closure an `UnsafeRawBufferPointer` over the referenced
storage, preserving alignment and the closure-scoped safety guarantee.

## See Also

- ``RAW_accessible_mutable``
- <doc:RAW_staticbuff>
- <doc:RAW_decodable>
- <doc:RAW_encodable>
