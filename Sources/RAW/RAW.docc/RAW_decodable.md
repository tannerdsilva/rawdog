# ``RAW/RAW_decodable``

## Overview

`RAW_decodable` defines the contract for types that can be initialized directly from
raw, durable memory storage. it is the primary mechanism for deserializing binary data
into strongly-typed Swift structures.

the central principle is **atomic consumption**: the buffer is indivisible. either
every byte in the buffer is consumed to create a valid instance, or initialization
fails entirely. there is no partial consumption.

## requirements

the protocol carries two requirements wired together by mutual defaults, so a
conformer implements whichever one it was written against:

- `init?(RAW_decode:)` — the v22 buffer initializer, taking an
  `UnsafeRawBufferPointer`
- `init?(RAW_decode:count:)` — the v21-compatible pointer + count initializer
  (deprecated in v22)

macro-generated types witness the v22 form; hand-written v21 code witnesses the v21
form. either way, construction dispatches through the witness table to the
conformer's concrete initializer.

```swift
public protocol RAW_decodable {
    @available(*, deprecated, message: "use init?(RAW_decode:) with an UnsafeRawBufferPointer")
    init?(RAW_decode: UnsafeRawPointer, count: Int)

    init?(RAW_decode: UnsafeRawBufferPointer)
}
```

### the consumption contract

1. **all-or-nothing** — the buffer length must exactly match the amount of data
   required to initialize the type.
2. **failure** — if the length is wrong (too short or too long), the initializer must
   return `nil`.
3. **semantics** — a successful (non-nil) result means the entirety of the buffer was
   consumed; a `nil` result means no part of the buffer is considered processed and
   the caller retains responsibility for the memory.

this contract is what lets rawdog chain decode operations safely: a successful decode
implies the read pointer can advance by exactly `buffer.count` bytes.

## variable vs. static length

rawdog is optimized for static allocation, but `RAW_decodable` handles
variable-length data too. the distinction is where the length is established before
the initializer runs:

- **static length** — the type knows its size at compile time (e.g. via
  ``RAW_fixed``). the initializer validates that `buffer.count` matches that known
  size.
- **variable length** — the type accepts a run of bytes of some runtime length (e.g. a
  null-terminated or length-prefixed string). the **caller** is responsible for
  handing the initializer a buffer that is exactly in bounds before calling it.

## adoption for RAW_staticbuff types

### automatic via @RAW_staticbuff

types declared with `@RAW_staticbuff(bytes:)` gain `RAW_decodable` automatically —
the macro generates an `init?(RAW_decode:)` that validates the buffer length against
the fixed size and copies the bytes into storage.

### hand-written: the macro pair

for hand-written storage, ``RAW_decode_decl(RAW_staticbuff:storage:)`` and
``RAW_decode_impl(RAW_staticbuff:storage:)`` generate the signature and body against
a key path into the type's storage:

```swift
struct FixedSizeBlock: RAW_decodable {
    var storage: (UInt8, UInt8, UInt8, UInt8) = (0, 0, 0, 0)

    RAW_decode_decl(
        RAW_staticbuff: FixedSizeBlock.self,
        storage: \.storage
    )

    init?(RAW_decode: UnsafeRawBufferPointer) {
        RAW_decode_impl(
            RAW_staticbuff: FixedSizeBlock.self,
            storage: \.storage
        )
    }
}

let bytes: [UInt8] = [1, 2, 3, 4]
bytes.withUnsafeBytes { buf in
    let block = FixedSizeBlock(RAW_decode: buf) // succeeds only if buf.count == 4
}
```

### hand-written: variable length

a variable-length conformer writes its own initializer and validates its own
boundaries:

```swift
struct CString: RAW_decodable {
    let contents: [UInt8]

    init?(RAW_decode buffer: UnsafeRawBufferPointer) {
        // reject embedded null terminators: this must be exactly one string
        for byte in buffer where byte == 0 {
            return nil
        }
        contents = [UInt8](buffer)
    }
}
```

## See Also

- <doc:RAW_encodable>
- <doc:RAW_fixed>
- <doc:RAW_staticbuff>
- <doc:RAW_accessible_immutable>
