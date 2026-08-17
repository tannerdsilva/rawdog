# RAW_accessible_mutable

@Metadata {
    @PageTitle("RAW_accessible_mutable")
    @Available(iOS, introduced: 1.0)
    @Available(macOS, introduced: 1.0)
    @Available(Linux, introduced: 1.0)
}

## Overview

The `RAW_accessible_mutable` protocol extends `RAW_accessible_immutable` to provide safe, **mutating** access to the underlying raw memory representation of a type. 

While immutable access is sufficient for reading and encoding data, certain operations—such as in-place decryption, checksum updates, or direct memory manipulation—require write access. `RAW_accessible_mutable` ensures that such access is granted safely through a closure-based model, preventing pointer escape and maintaining Swift's memory safety guarantees even when dealing with raw bytes.

Because this protocol inherits from `RAW_accessible_immutable`, any type conforming to `RAW_accessible_mutable` automatically supports both reading and writing operations.

## Protocol Requirements

Conforming types must implement a single mutating requirement that grants access to an `UnsafeMutableRawBufferPointer`. 

```swift
public protocol RAW_accessible_mutable: RAW_accessible_immutable {
    mutating func RAW_access_mutable<R, E>(
        _: UnsafeMutableRawBufferPointer.Type, 
        _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R
    ) throws(E) -> R where E: Swift.Error
}
```

### Method Signature Breakdown

- **`mutating`**: Indicates that the access may modify the underlying memory of the conforming instance.
- **`UnsafeMutableRawBufferPointer.Type`**: A type sentinel used to disambiguate this method from the immutable variant and convenience overloads.
- **`body`**: A closure receiving the mutable buffer pointer. All write operations must occur within this scope.
- **`throws(E)`**: Supports Swift's typed throws, allowing precise error propagation during mutable operations.

## Default Implementations

The `rawdog` library provides several extensions to reduce boilerplate and improve ergonomics when working with mutable raw data.

### UInt8 Buffer Conversion

Similar to the immutable protocol, a default implementation is provided to convert the raw mutable pointer into a typed `UnsafeMutableBufferPointer<UInt8>`. This is the most common use case for byte-level manipulation.

```swift
extension RAW_accessible_mutable {
    public mutating func RAW_access_mutable<R, E>(
        _: UnsafeMutableBufferPointer<UInt8>.Type, 
        _ body: (UnsafeMutableBufferPointer<UInt8>) throws(E) -> R
    ) throws(E) -> R where E: Swift.Error {
        return try RAW_access_mutable(UnsafeMutableRawBufferPointer.self) { buff throws(E) -> R in
            return try body(.init(
                start: buff.baseAddress?.assumingMemoryBound(to: UInt8.self), 
                count: buff.count
            ))
        }
    }
}
```

### Convenience Overloads (Legacy & Syntactic Sugar)

To further simplify syntax (especially from code that was using prior versions of rawdog), convenience overloads are provided for both `RAW_accessible_immutable` and `RAW_accessible_mutable`. These methods omit the type sentinel argument, defaulting to `UInt8` buffer pointers. This allows for cleaner closure-based syntax when the specific pointer type is inferred.

**Mutable Convenience Overload:**
```swift
extension RAW_accessible_mutable {
    public mutating func RAW_access_mutable<R, E>(
        _ body: (UnsafeMutableBufferPointer<UInt8>) throws(E) -> R
    ) throws(E) -> R where E: Swift.Error {
        return try RAW_access_mutable(UnsafeMutableBufferPointer<UInt8>.self, body)
    }
}
```

**Immutable Convenience Overload:**
```swift
extension RAW_accessible_immutable {
    public borrowing func RAW_access_immutable<R, E>(
        _ body: (UnsafeBufferPointer<UInt8>) throws(E) -> R
    ) throws(E) -> R where E: Swift.Error {
        return try RAW_access_immutable(UnsafeBufferPointer<UInt8>.self, body)
    }
}
```

With these extensions, you can call access methods without passing `.self` types, provided the closure argument type is clear.

## Automatic Conformance via Macros

Manual implementation of mutable access logic is prone to errors regarding memory binding and exclusivity. The `rawdog` package provides macros to automate conformance for types utilizing `RAW_staticbuff`.

### Declaration Macro

The `RAW_access_mutable_decl` macro generates the required function signature within your type.

```swift
@freestanding(declaration, names: named(RAW_access_mutable(_:_:)))
public macro RAW_access_mutable_decl<S: RAW_staticbuff>(
    RAW_staticbuff: S.Type, 
    storage: KeyPath<S, S.RAW_fixed_type>
) = #externalMacro(module: "RAW_macros", type: "RAW_accessible_mutable_fixed_macro")
```

### Implementation Macro

The `RAW_access_mutable_impl` macro injects the safe memory access logic into the function body.

```swift
@attached(body)
public macro RAW_access_mutable_impl<S: RAW_staticbuff>(
    RAW_staticbuff: S.Type, 
    storage: KeyPath<S, S.RAW_fixed_type>
) = #externalMacro(module: "RAW_macros", type: "RAW_accessible_mutable_fixed_macro")
```

These macros ensure that the mutable pointer is derived correctly from the static storage keypath, maintaining alignment and safety guarantees.

## Example Adoption

The following example demonstrates conforming to `RAW_accessible_mutable` using the macros, and utilizing the convenience overloads for clean syntax.

```swift
struct MutableBinaryData: RAW_accessible_mutable {
    var storage: StaticBuffer<1024>

    // Generate declaration and implementation using macros
    RAW_access_mutable_decl(
        RAW_staticbuff: StaticBuffer<1024>.self, 
        storage: \.storage
    )

    mutating func RAW_access_mutable<R, E>(
        _: UnsafeMutableRawBufferPointer.Type, 
        _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R
    ) throws(E) -> R where E: Swift.Error 
    RAW_access_mutable_impl(
        RAW_staticbuff: StaticBuffer<1024>.self, 
        storage: \.storage
    )
}

// Usage with convenience overload (no type sentinel needed)
var data = MutableBinaryData()
try data.RAW_access_mutable { buffer in
    // buffer is UnsafeMutableBufferPointer<UInt8>
    buffer[0] = 0xFF
}
```

## Safety Considerations

When using `RAW_accessible_mutable`, ensure that:

1.  **Exclusive Access:** Do not attempt to access the same memory location from another thread or closure while the `body` closure is executing.
2.  **Type Binding:** When assuming memory bound to specific types within the closure, ensure the size and alignment match the underlying storage.
3.  **Initialization:** Ensure memory is initialized before reading from it, even when accessed mutably.

## See Also

- <doc:RAW_accessible_immutable>
- <doc:RAW_staticbuff>
- <doc:RAW_macros>
- [README](<root:README>)