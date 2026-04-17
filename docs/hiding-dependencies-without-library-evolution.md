# Internal bridging header

The new internal bridging header, a bridging header imported as internal, makes hiding project local headers straightforward. This header can then be referenced only from implementation details and the compiler will error on references from API, as you expect from an internal import.

The internal bridging header works with or without library-evolution. The non-library-evolution mode implies more restrictions as we discuss next.

# Hiding a dependency without library-evolution

While the compiler used to accept and apply `@_implementationOnly` imports without library-evolution, it was known to cause memory-corruption at runtime as the compiler wasn't taking into account the additional constraints in that mode. The different constraints are also why an `internal import` hides dependencies only in library-evolution mode.

A module built in library-evolution mode is more permissive as it uses indirection by default for function calls, memory accesses and describing memory layout. This allows library-evolution mode to hide dependencies from clients in most cases, unless references are marked `public`, `@frozen`, or `@inlinable`.

Without library-evolution there are more constraints as the default is switched, the same information must be visible to the client by default. Notably memory layouts must be known by clients, so even `internal` types must be visible to clients by default as they can contribute to the memory layout of `public` types.

The latest improvement is the compiler support to check these constraints specific to non-library-evolution and ways to identify types that depend on a hidden dependency directly or indirectly even if the type is non-public. With this check hiding dependencies without library-evolution becomes safe but may require some additional work and annotations.

# How to use

## Dependencies

There are two alternative ways to hide a dependency. Both provide similar results but the configuration differs. Both can be used together in the same module if needed.

### 1.1 Internal bridging header

Use a bridging header from your Xcode framework as you would from an app target, but mark the header as internal using the flag `-internal-import-bridging-header`. When enabled the bridging header isn't visible to clients and you automatically get proper type-checking specific to the non-library-evolution mode.


### 1.2 Implementation-only import of a module

To hide a direct import of a module you must first adopt `CheckImplementationOnly` which ensures the dependencies are correctly used from the source code. To do so pass the flags `-enable-experimental-feature CheckImplementationOnly` to the compiler.

Mark each dependency to hide from clients using the attribute `@_implementationOnly` on the import statement:

```
@_implementationOnly import HiddenDependency
```

All files importing HiddenDependency must use the attribute, if a single file has an import without the attribute the dependency will be visible to clients.

The attribute `@_implementationOnly` is parallel to internal imports, as described above in non-library-evolution mode `@_implementationOnly` is more restrictive. However one can declare an `@_implementationOnly` internal import, where the internal can be implicit if using `InternalImportsByDefault`. There is no real advantage to it but it should be usable without issues except for some duplicated errors on invalid code.

Safe implementation-only in non-library-evolution mode is tracked by rdar://152662470. Compilers in earlier toolchains may recognize `CheckImplementationOnly` but be aware that it may be too strict and reject more code than it needs to.

2. References from API

As with hiding dependencies with library-evolution, hidden dependencies imported via the internal bridging header or `@_implementationOnly` cannot be referenced from API. Public function signatures cannot use types from hidden dependencies and inlinable code cannot call functions. The same restrictions from library-evolution are applied in non-library-evolution, plus the ones described next.

3. Use in types

Types with memory layouts depending on a hidden dependency must be marked `@_implementationOnly`. This applies to non-public structs using an imported type in a stored property. It applies to structs, classes and protocols for conformances and inheritance declarations too.

```
@_implementationOnly struct LocalStruct {
  var prop: HiddenDependency.HiddenType
}

struct LocalStructNotOk {
  var prop: HiddenDependency.HiddenType // error: cannot use struct 'HiddenType' in a property declaration member of a type not marked '@_implementationOnly'; 'HiddenDependency' has been imported as implementation-only
}
```

This behavior is transitive, a type itself marked `@_implementationOnly` can only be referenced from memory-layouts themselves marked as `@_implementationOnly`. This ensures that public type memory-layouts and other information visible to clients never depend on an `@_implementationOnly` dependency or type.

```
@_implementationOnly struct IndirectStruct {
  var prop: LocalStruct
}

struct IndirectStructNotOk {
  var prop: LocalStruct // error: cannot use struct 'LocalStruct' in a property declaration member of a type not marked '@_implementationOnly'; 'LocalStruct' is marked '@_implementationOnly'
}
```

Classes can reference `@_implementationOnly` dependencies and types from non-public stored properties. The class can be public or less-than-public, but not open. (We could likely refine this restriction as references may be allowed from final stored properties, please file a Radar with a real world use case if this is an issue.)

```
public class IndirectClass {
  internal var propA: HiddenDependency.HiddenType
  internal var propB: LocalStruct

  public var propC: HiddenDependency.HiddenType // error: cannot use struct 'HiddenType' in a property declaration marked public or in a '@frozen' or '@usableFromInline' context; 'HiddenDependency' has been imported as implementation-only
  public var propD: LocalStruct // error: cannot use struct 'LocalStruct' in a property declaration marked public or in a '@frozen' or '@usableFromInline' context; 'LocalStruct' is marked '@_implementationOnly'
}
```

To store a property with an `@_implementationOnly` type, imported or local, in a struct one can use a class as indirection or a protocol to abstract away the hidden type.

4. Use in function signatures and bodies

In default non-library-evolution mode, non-public functions can reference `@_implementationOnly` types and functions, they are only rejected in public function signatures. Optimizations should automatically avoid inlining functions with such references in clients, no need to add attributes.

```
// Classic/non-embedded mode
internal func signatureInternal(a: HiddenDependency.HiddenType) {}

public func signaturePublic(a: HiddenDependency.HiddenType) {} // error: struct 'HiddenType' cannot be used in an '@inlinable' function because 'HiddenDependency' was imported implementation-only

public func body() {
  let _: HiddenDependency.HiddenType
}
```
However in embedded mode, functions are inlined in clients by default even the non-public ones. The signature restriction on public functions still applies. On top of it a function referencing an `@_implementationOnly` type or function in its body or signature (no matter if it's public or not) must be marked `@export(interface)`. This will ensure the function is emitted in the local object file and not in the clients.

```
// Embedded mode
@export(interface)
internal func signatureInternalOk(a: HiddenDependency.HiddenType) {}

internal func signatureInternal(a: HiddenDependency.HiddenType) {} // error: struct 'HiddenType' cannot be used in an embedded function not marked '@export(interface)' because 'HiddenDependency' was imported implementation-only

public func signaturePublic(a: HiddenDependency.HiddenType) {} // error: struct 'HiddenType' cannot be used in an embedded function not marked '@export(interface)' because 'HiddenDependency' was imported implementation-only

@export(interface)
public func bodyHidden() {
  let _: HiddenDependency.HiddenType
}

public func bodyEmittedInClientsByDefault() {
  let _: HiddenDependency.HiddenType // error: struct 'HiddenType' cannot be used in an embedded function not marked '@export(interface)' because 'HiddenDependency' was imported implementation-only
  let _: LocalStruct // error: struct 'LocalStruct' cannot be used in an embedded function not marked '@export(interface)' because 'LocalStruct' is marked '@_implementationOnly'
}
```

# Looking ahead

As long term plan we are looking at allowing more references to the hidden dependency, lifting the need to mark types as `@_implementationOnly` and bringing the non-library-evolution closer to the library-evolution one. Hopefully we wouldn't need an official spelling for `@_implementationOnly` on types then, and use the official `internal import` for the import statement, likely with some configuration option.

I believe then we should still allow to have an `internal import` that does not hide the dependency. Projects generally avoid library-evolution for performance concerns, and hiding a dependency inherently limits what the compiler can optimize and thus would affect performance. It may be counter productive to hide dependencies automatically in non-library-evolution mode. This is especially a concern with `InternalImportsByDefault` that is scheduled to become the default in Swift 7.

For example, an app composed of a few different local modules may not have a practical need to hide these dependencies. Or a swiftpm project relying on packages distributed with their full source may get a performance loss if a dependency is hidden even when available.

However there are still use cases when hiding dependencies is important. The use of project local headers as mentioned above or to isolate a dependency from the clients to avoid conflict, like we see with BoringSSL.

Plus access-modifiers on imports like `internal import` have two meanings. (1) At the individual source file level they ensure no API rely on the imported module, which may prevent undesired leak of implementation details. (2) At the module level, if all imports of a dependency are marked as `import` or below, the dependency is hidden from clients. Only (2) differs between both modes and could be controlled separately.

There are a few alternatives to determine what dependencies are hidden from clients:

1. Hide by default with possibility to opt-out, `internal import` hides the dependency but a `@visible internal import` would ensure the dependency isn't referred from API but still visible to clients. I tend to rule this alternative out as the default being the least performance oriented alternative, and the undesired behavior in the simple app use case makes it impractical.

2. Visible dependency by default with opt-in hiding, `@hidden internal import` would mark a dependency as fully hidden from clients. It would then trigger everything that is needed to ensure not even internal types depend on the dependency in a way that could affect clients. A project would use this version only on dependencies that cannot be shared with clients, which is likely the exception.

3. Hiding the dependency or not is a module-level concern, maybe it should be treated as such. A new compiler flag in the style of `-hide-dependency MyProject_Internal -hide-dependency MyBoringSSLWrapper` could list hidden dependencies and trigger the desired behavior. We could see the package manifest identify the modules to be hidden.

I am leaning towards 2. and 3., maybe more 3. The module-level approach implies that sources would be affected by an outside configuration but it's also a cleaner and more centralized way to keep the configuration.
