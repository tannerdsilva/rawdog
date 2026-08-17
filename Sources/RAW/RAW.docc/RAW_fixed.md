# ``RAW/RAW_fixed``

## Overview

The `RAW_fixed` protocol identifies types whose memory size is known at compile time. In the `rawdog` ecosystem, this is a foundational concept for static memory allocation. By expressing size through an associated type rather than a runtime property, `rawdog` can optimize memory layout, perform compile-time checks, and eliminate the overhead of dynamic size calculations during binary encoding and decoding.

Types conforming to `RAW_fixed` declare a `RAW_fixed_type` associated type. The size of the conforming instance is derived directly from `MemoryLayout<RAW_fixed_type>.size`. This allows `rawdog` to treat complex structures as fixed-size blocks of memory, similar to C structs or static arrays.

## Protocol Requirements

Conforming types must define a single associated type that represents their fixed memory layout.

```swift
public protocol RAW_fixed {
    associatedtype RAW_fixed_type
}
```

### Size Determination

The effective size of any `RAW_fixed` conformer is calculated as:

```swift
let size = MemoryLayout<Conformer.RAW_fixed_type>.size
```

### Important Considerations

- **Stride and Alignment:** The `RAW_fixed` protocol itself does not enforce or consider stride and alignment in its requirements. It strictly concerns itself with the total size in bytes. However, the underlying `RAW_fixed_type` (often a tuple) will naturally adhere to Swift's memory alignment rules.
- **Typical Implementations:** The `RAW_fixed_type` is almost always a tuple of bytes (e.g., `(UInt8, UInt8, UInt8)`) or a tuple of individual types that themselves conform to `RAW_fixed`. This composability allows complex structures to be built from fixed-size primitives while maintaining a known total size.

## Automatic Conformance via Macros

Manually defining fixed-size tuples for every structure is verbose and difficult to maintain. `rawdog` provides macros to automate the definition of the `RAW_fixed_type` and the conformance itself.

### Attached Extension Macro

The `RAW_fixed(bytes:)` macro is an attached extension macro. When applied to a type, it automatically generates an extension that conforms the type to `RAW_fixed` and defines the `RAW_fixed_type` based on the specified byte count.

```swift
@attached(extension, conformances: RAW_fixed)
public macro RAW_fixed(bytes: Int) = #externalMacro(module: "RAW_macros", type: "RAW_fixed_macro_bytes")
```

This is the preferred method for most use cases, as it keeps the conformance logic external to the type definition while ensuring consistency.

### Freestanding Declaration Macro

For scenarios where explicit control over the typealias is required inside the type definition, the `RAW_fixed_type(bytes:)` macro generates the `typealias RAW_fixed_type` declaration.

```swift
@freestanding(declaration, names: named(RAW_fixed_type))
public macro RAW_fixed_type(bytes: Int) = #externalMacro(module: "RAW_macros", type: "RAW_fixed_type_macro_bytes")
```

This macro is useful when you need to satisfy the protocol requirement manually but want to avoid writing out large tuple types explicitly.

## Example Adoption

### Using the Attached Macro

The following example demonstrates the simplest way to adopt `RAW_fixed` for a structure intended to hold 16 bytes of data.

```swift
@RAW_fixed(bytes: 16)
struct FixedSizeBlock {
    // Implementation details...
}

// Verification
let size = MemoryLayout<FixedSizeBlock.RAW_fixed_type>.size // 16
```

### Using the Freestanding Macro

If you prefer to define the typealias within the struct body:

```swift
struct FixedSizeBlock: RAW_fixed {
    RAW_fixed_type(bytes: 16)
    
    // Implementation details...
}
```

### Composability

Because `RAW_fixed_type` can be composed of other `RAW_fixed` types, you can build larger structures from smaller ones while maintaining compile-time size knowledge.

```swift
struct Header: RAW_fixed {
    RAW_fixed_type(bytes: 4)
}

struct Payload: RAW_fixed {
    RAW_fixed_type(bytes: 64)
}

@RAW_fixed(bytes: 68) // 4 + 64
struct Packet {
    // Composition logic...
}
```

## See Also

- <doc:RAW_accessible_immutable>
- <doc:RAW_accessible_mutable>
- <doc:RAW_staticbuff>
- [README](<root:README>)
