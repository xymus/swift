// RUN: %empty-directory(%t)
// RUN: split-file %s %t --leading-lines

/// Generate cdecl.h
// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) \
// RUN:   %t/Lib.swift -emit-module -verify -o %t -emit-module-doc \
// RUN:   -emit-objc-header-path %t/cdecl.h \
// RUN:   -disable-objc-attr-requires-foundation-module \
// RUN:   -enable-experimental-feature CDeclOfficial

/// Check cdecl.h directly
// RUN: %FileCheck %s --input-file %t/cdecl.h
// RUN: %check-in-clang %t/cdecl.h
// RUN: %check-in-clang-c %t/cdecl.h -Wnullable-to-nonnull-conversion
// RUN: %check-in-clang -fno-modules -Qunused-arguments %t/cdecl.h \
// RUN:   -include ctypes.h -include CoreFoundation.h
// RUN: %check-in-clang-c -fno-modules -Qunused-arguments %t/cdecl.h \
// RUN:   -include ctypes.h -include CoreFoundation.h

/// Build client against cdecl.h
// RUN: %clang -c %t/Client.c -fobjc-arc -fmodules -I %t \
// RUN:   -F %S/../Inputs/clang-importer-sdk-path/frameworks \
// RUN:   -I %clang-include-dir -Werror \
// RUN:   -isysroot %S/../Inputs/clang-importer-sdk

//--- Lib.swift

// C     HECK-LABEL: // Module content for C clients

#if os(Windows) && (arch(x86_64) || arch(arm64))
@objc enum CEnum: Int32 { case A, B }
#else
@objc enum CEnum: Int { case A, B }
#endif

@cdecl("cEnum")
func cEnum(x: CEnum) {}

/// Documentation
@cdecl("foo_bar")
func foo(x: Int, bar y: Int) {}
// CHECK-DAG: // Documentation
// CHECK-DAG: SWIFT_EXTERN void foo_bar(NSInteger x, NSInteger y) SWIFT_NOEXCEPT;
// CHECK-DAG: SWIFT_EXTERN void foo_bar(ptrdiff_t x, ptrdiff_t y) SWIFT_NOEXCEPT;

@cdecl("primitiveTypesUser")
public func g_primitiveTypesUser(i: Int, f: Float, c: CChar) {}
// CHECK-DAG: SWIFT_EXTERN void primitiveTypesUser(NSInteger i, float f, char c) SWIFT_NOEXCEPT;
// CHECK-DAG: SWIFT_EXTERN void primitiveTypesUser(ptrdiff_t i, float f, char c) SWIFT_NOEXCEPT;

@cdecl("has_keyword_arg_names")
func keywordArgNames(auto: Int, union: Int) {}
// CHECK-DAG: SWIFT_EXTERN void has_keyword_arg_names(NSInteger auto_, NSInteger union_) SWIFT_NOEXCEPT;
// CHECK-DAG: SWIFT_EXTERN void has_keyword_arg_names(ptrdiff_t auto_, ptrdiff_t union_) SWIFT_NOEXCEPT;

@cdecl("return_never")
func returnNever() -> Never { fatalError() }
// CHECK-DAG: SWIFT_EXTERN void return_never(void) SWIFT_NOEXCEPT SWIFT_NORETURN;
// CHECK-DAG: SWIFT_EXTERN void return_never(void) SWIFT_NOEXCEPT SWIFT_NORETURN;

@cdecl("s_block_nightmare")
public func s_block_nightmare(x: @convention(block) (Int) -> Float)
  -> @convention(block) (CChar) -> Double { return { _ in 0 } }
// CHECK-DAG: SWIFT_EXTERN double (^ _Nonnull s_block_nightmare(SWIFT_NOESCAPE float (^ _Nonnull x)(NSInteger)))(char) SWIFT_NOEXCEPT SWIFT_WARN_UNUSED_RESULT;

@cdecl("block_recurring_nightmare")
public func t_block_recurring_nightmare(x: @escaping @convention(block) (@convention(block) (Double) -> Int) -> Float)
  -> @convention(block) (_ asdfasdf: @convention(block) (CUnsignedChar) -> CChar) -> Double {
  fatalError()
}
// CHECK-DAG: SWIFT_EXTERN double (^ _Nonnull block_recurring_nightmare(float (^ _Nonnull x)(SWIFT_NOESCAPE NSInteger (^ _Nonnull)(double))))(SWIFT_NOESCAPE char (^ _Nonnull)(unsigned char)) SWIFT_NOEXCEPT SWIFT_WARN_UNUSED_RESULT;

@cdecl("function_pointer_nightmare")
func u_function_pointer_nightmare(x: @convention(c) (Int) -> Float)
  -> @convention(c) (CChar) -> Double { return { _ in 0 } }
// CHECK-DAG: SWIFT_EXTERN double (* _Nonnull function_pointer_nightmare(float (* _Nonnull x)(NSInteger)))(char) SWIFT_NOEXCEPT SWIFT_WARN_UNUSED_RESULT;

@cdecl("function_pointer_recurring_nightmare")
public func v_function_pointer_recurring_nightmare(x: @escaping @convention(c) (@convention(c) (Double) -> Int) -> Float)
  -> @convention(c) (@convention(c) (CUnsignedChar) -> CChar) -> Double {
  fatalError()
}
// CHECK-DAG: SWIFT_EXTERN double (* _Nonnull function_pointer_recurring_nightmare(float (* _Nonnull x)(NSInteger (* _Nonnull)(double))))(char (* _Nonnull)(unsigned char)) SWIFT_NOEXCEPT SWIFT_WARN_UNUSED_RESULT;

//@objc
//public enum E : Int {
//    case a
//    case b
//}
//
//@cdecl("enum_E")
//public func enumUser(e: E) {}

public func optionalUser(i: Int?) {}

//--- Client.c

#include "cdecl.h"

int main() {
    foo_bar(42, 43);
    return_never();
}
