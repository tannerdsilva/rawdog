# native value types

wrap native Swift values — integers, floats, and strings — in rawdog's statically
sized raw storage, bridging them through ``RAW_native``.

## Overview

rawdog's "native value" types are ``RAW_staticbuff`` types that wrap a native Swift
value in their raw storage, so that a plain `UInt32`, `Float`, or `String` can live in
a byte buffer with a statically known layout. the bridge between the native value and
the raw bytes is ``RAW_native``:

```swift
public protocol RAW_native {
    associatedtype RAW_native_type
    init(RAW_native: RAW_native_type)
    func RAW_native() -> RAW_native_type
}
```

a conformer states what native type it encodes, and how to convert both ways.

## fixed-width integers

``RAW_encoded_fixedwidthinteger`` is `RAW_native`-with-`RAW_staticbuff` for
`FixedWidthInteger` native types. the `@RAW_staticbuff_fixedwidthinteger_type` macro
generates the `RAW_native` witnesses and attaches the conformance, given the storage
size, the integer type, and the desired endianness:

```swift
@RAW_staticbuff(bytes: 4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian: true)
struct UInt32BigEndian: RAW_staticbuff {}

let value = UInt32BigEndian(RAW_native: 0x01020304)   // stored big-endian
let back: UInt32 = value.RAW_native()
```

types that also adopt `ExpressibleByIntegerLiteral` get integer literals for free:

```swift
let value: UInt32BigEndian = 0x01020304
```

``RAW_byte`` is the built-in example: a one-byte, little-endian `UInt8` wrapper.

## binary floating point

``RAW_encoded_binaryfloatingpoint`` is the same idea for `BinaryFloatingPoint` native
types, via the `@RAW_staticbuff_binaryfloatingpoint_type` macro:

```swift
@RAW_staticbuff(bytes: 4)
@RAW_staticbuff_binaryfloatingpoint_type<Float>()
struct Float32: RAW_staticbuff {}

let value = Float32(RAW_native: 3.14)
```

## unicode strings

``RAW_encoded_unicode`` models a unicode string stored as raw bytes in a backing
integer encoding, and gains full `RAW_accessible`, `RAW_decodable`, `RAW_encodable`,
`RAW_comparable`, and `Sequence<Character>` support. the
`@RAW_convertible_string_type` macro generates the whole conformance from a
`UnicodeCodec` and a backing integer type:

```swift
@RAW_convertible_string_type<UTF8>(backing: UInt32BigEndian.self)
struct MyString: RAW_encoded_unicode {}

let str = MyString("hello, rawdog")
for character in str {
    print(character)
}
```

the type round-trips with `String`, decodes from and encodes to raw buffers, compares
scalar-by-scalar, and iterates as a sequence of `Character` values through
``RAW_encoded_unicode_iterator``.

## See Also

- <doc:RAW_staticbuff>
- ``RAW_native``
- ``RAW_encoded_fixedwidthinteger``
- ``RAW_encoded_binaryfloatingpoint``
- ``RAW_encoded_unicode``
- ``RAW_byte``
