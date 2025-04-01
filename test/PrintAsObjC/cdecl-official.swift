// RUN: %empty-directory(%t)
// RUN: split-file %s %t --leading-lines

// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) \
// RUN:   -enable-source-import -emit-module -emit-module-doc \
// RUN:   -o %t %s -disable-objc-attr-requires-foundation-module
// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) \
// RUN:   -parse-as-library %t/cdecl.swiftmodule -typecheck -verify \
// RUN:   -emit-objc-header-path %t/cdecl.h -import-objc-header %S/../Inputs/empty.h \
// RUN:   -disable-objc-attr-requires-foundation-module

// RUN: %FileCheck %s < %t/cdecl.h
// RUN: %check-in-clang %t/cdecl.h
// RUN: %check-in-clang-c %t/cdecl.h
// RUN: %check-in-clang -fno-modules -Qunused-arguments %t/cdecl.h \
// RUN:   -include ctypes.h -include CoreFoundation.h
// RUN: %check-in-clang-c -fno-modules -Qunused-arguments %t/cdecl.h \
// RUN:   -include ctypes.h -include CoreFoundation.h


//--- Lib.swift

// CK: /// What a nightmare!
// CK-LABEL: SWIFT_EXTERN double (^ _Nonnull block_nightmare(SWIFT_NOESCAPE float (^ _Nonnull x)(NSInteger)))(char) SWIFT_NOEXCEPT SWIFT_WARN_UNUSED_RESULT;

/// What a nightmare!
@_cdecl("block_nightmare")
public func block_nightmare(x: @convention(block) (Int) -> Float)
  -> @convention(block) (CChar) -> Double { return { _ in 0 } }

// CK-LABEL: SWIFT_EXTERN double (^ _Nonnull block_recurring_nightmare(float (^ _Nonnull x)(SWIFT_NOESCAPE NSInteger (^ _Nonnull)(double))))(SWIFT_NOESCAPE char (^ _Nonnull)(unsigned char)) SWIFT_NOEXCEPT SWIFT_WARN_UNUSED_RESULT;
//@_cdecl("block_recurring_nightmare")
//public func block_recurring_nightmare(x: @escaping @convention(block) (@convention(block) (Double) -> Int) -> Float)
//  -> @convention(block) (_ asdfasdf: @convention(block) (CUnsignedChar) -> CChar) -> Double {
//  fatalError()
//}

// CHECK-LABEL: SWIFT_EXTERN void foo_bar(NSInteger x, NSInteger y) SWIFT_NOEXCEPT;
// CHECK-LABEL: SWIFT_EXTERN void foo_bar(ptrdiff_t x, ptrdiff_t y) SWIFT_NOEXCEPT;
@_cdecl("foo_bar")
func foo(x: Int, bar y: Int) {}

// CK-LABEL: SWIFT_EXTERN double (* _Nonnull function_pointer_nightmare(float (* _Nonnull x)(NSInteger)))(char) SWIFT_NOEXCEPT SWIFT_WARN_UNUSED_RESULT;
//@_cdecl("function_pointer_nightmare")
//func function_pointer_nightmare(x: @convention(c) (Int) -> Float)
//  -> @convention(c) (CChar) -> Double { return { _ in 0 } }

// CK-LABEL: SWIFT_EXTERN double (* _Nonnull function_pointer_recurring_nightmare(float (* _Nonnull x)(NSInteger (* _Nonnull)(double))))(char (* _Nonnull)(unsigned char)) SWIFT_NOEXCEPT SWIFT_WARN_UNUSED_RESULT;
//@_cdecl("function_pointer_recurring_nightmare")
//public func function_pointer_recurring_nightmare(x: @escaping @convention(c) (@convention(c) (Double) -> Int) -> Float)
//  -> @convention(c) (@convention(c) (CUnsignedChar) -> CChar) -> Double {
//  fatalError()
//}
  
// CHECK-LABEL: SWIFT_EXTERN void has_keyword_arg_names(NSInteger auto_, NSInteger union_) SWIFT_NOEXCEPT;
@_cdecl("has_keyword_arg_names")
func keywordArgNames(auto: Int, union: Int) {}

@objc
class C {}

// CK-LABEL: SWIFT_EXTERN C * _Null_unspecified return_iuo(void) SWIFT_NOEXCEPT SWIFT_WARN_UNUSED_RESULT;
//@_cdecl("return_iuo") // expected-error XYTODO require @objc
//func returnIUO() -> C! { return C() }

// CHECK-LABEL: SWIFT_EXTERN void return_never(void) SWIFT_NOEXCEPT SWIFT_NORETURN;
@_cdecl("return_never")
func returnNever() -> Never { fatalError() }

// CK-LABEL: SWIFT_EXTERN void takes_iuo(C * _Null_unspecified c) SWIFT_NOEXCEPT;
//@_cdecl("takes_iuo")
//func takesIUO(c: C!) {}
