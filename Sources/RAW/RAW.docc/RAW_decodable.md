# ``RAW/RAW_decodable``

@Metadata {
    @PageTitle("RAW_decodable")
    @Available(iOS, introduced: 1.0)
    @Available(macOS, introduced: 1.0)
    @Available(Linux, introduced: 1.0)
}

## Overview

The `RAW_decodable` protocol defines the contract for types that can be initialized directly from raw, durable memory storage. In the `rawdog` ecosystem, this is the primary mechanism for deserializing binary data into strongly-typed Swift structures.

The central principle of `RAW_decodable` is **atomic consumption**. When a type attempts to initialize from a buffer, it must treat the buffer as an indivisible unit: either every byte in the buffer is consumed to create a valid instance, or the initialization fails entirely. There is no partial consumption.

This protocol is agnostic regarding memory layout size. It works equally well for:
- **Fixed-size structures:** Where the expected length is known at compile time (e.g., a 16-byte UUID).
- **Variable-length data:** Where the expected length is determined at runtime (e.g., a length-prefixed string or a dynamic array), provided the caller ensures the buffer boundary matches the data's extent before calling the initializer.

## Protocol Requirements

Conforming types must implement a single failable initializer that accepts an `UnsafeRawBufferPointer`.

```swift
public protocol RAW_decodable {
    init?(RAW_decode buffer: UnsafeRawBufferPointer)
}
```

### The Consumption Contract

The behavior of this initializer is strictly defined to ensure safe memory management and parsing logic:

1.  **All-or-Nothing:** The length of the provided `buffer` must exactly match the amount of data required to initialize the type.
2.  **Failure Condition:** If the buffer length does not match the expected size (either too short or too long), the initializer **must** return `nil`.
3.  **Semantic Guarantee:** 
    - **Success:** If the initializer returns an instance, the **entirety** of the buffer is considered consumed.
    - **Failure:** If the initializer returns `nil`, the buffer is considered **not consumed**. The caller retains responsibility for the memory, and no data within the buffer should be considered processed.

This contract allows `rawdog` to chain decoding operations safely. A successful decode implies the read pointer can be advanced by exactly `buffer.count` bytes.

## Variable vs. Static Length

While `rawdog` is optimized for static memory allocation, `RAW_decodable` is designed to handle variable-length data as well. The distinction lies in how the buffer length is determined before the initializer is called.

- **Static Length:** The type inherently knows its size (e.g., via `RAW_fixed`). The initializer simply validates that `buffer.count` matches this known size.
- **Variable Length:** The type may support multiple sizes (e.g., a string or a flexible array). In this case, the **caller** is responsible for ensuring the buffer contains exactly the right amount of data (e.g., delimited by a null terminator or a length prefix) before passing it to `RAW_decode`.

## Automatic Conformance for Static Buffers

For types that utilize `RAW_staticbuff` for storage, manually implementing memory copying logic is unnecessary. `rawdog` provides macros to automate the generation of the initializer signature and the safe memory copying logic.

### Declaration Macro

The `RAW_decode_decl` macro generates the required initializer signature.

```swift
@freestanding(declaration, names: named(init(RAW_decode:)))
public macro RAW_decode_decl<S: RAW_staticbuff>(
    RAW_staticbuff: S.Type, 
    storage: KeyPath<S, S.RAW_fixed_type>
) = #externalMacro(module: "RAW_macros", type: "RAW_decodable_fixed_init_macro")
```

### Implementation Macro

The `RAW_decode_impl` macro injects the logic to validate buffer length and copy data into the storage property.

```swift
@attached(body)
public macro RAW_decode_impl<S: RAW_staticbuff>(
    RAW_staticbuff: S.Type, 
    storage: KeyPath<S, S.RAW_fixed_type>
) = #externalMacro(module: "RAW_macros", type: "RAW_decodable_fixed_init_macro")
```

## Examples

### Variable-Length Implementation

The following example demonstrates a simple variable-length type that wraps a byte array. It conforms to `RAW_decodable` by validating that the buffer is non-empty and copying the contents.

```swift
struct MyCustomStringStructure: RAW_decodable {
    private let contents:[UInt8]
    init?(RAW_decode buffer: UnsafeRawBufferPointer) {
        // validate that the buffer does not contain any null terminator bytes, as this would indicate that there are multiple strings within the contents of this `buffer` argument
		for byte in buffer {
			guard byte != 0x0 else {
				return nil
			}
		}
		// validation complete, this is a single continuous string.
		contents = [UInt8](buffer)
    }
}

// Usage
let stringData = [UInt8]("Hello this is a string!".utf8)
stringData.withUnsafeBytes { buffer in
    if let wrapper = ByteArrayWrapper(RAW_decode: buffer) {
        // Success: all 3 bytes consumed
    }
}
```

### Static-Length Implementation (Using Macros)

For fixed-size structures, the macros reduce boilerplate and ensure alignment safety.

```swift
struct FixedSizeBlock: RAW_decodable {
    var storage: StaticBuffer<64>

    // Generate declaration and implementation using macros
    RAW_decode_decl(
        RAW_staticbuff: StaticBuffer<64>.self, 
        storage: \.storage
    )

    init?(RAW_decode buffer: UnsafeRawBufferPointer) 
    RAW_decode_impl(
        RAW_staticbuff: StaticBuffer<64>.self, 
        storage: \.storage
    )
}

// Usage
// The initializer will automatically return nil if buffer.count != 64
```

## See Also

- <doc:RAW_fixed>
- <doc:RAW_accessible_immutable>
- <doc:RAW_staticbuff>
- <doc:RAW_macros>
- [README](<root:README>)