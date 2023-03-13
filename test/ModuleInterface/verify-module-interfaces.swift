// RUN: %empty-directory(%t)

// Check that verification won't reject a valid interface:
// RUN: %target-build-swift -emit-library -enable-library-evolution -emit-module-interface -emit-module -swift-version 5 -o %t/MyModule.o -verify-emitted-module-interface -module-name MyModule %s

// Check that verification will reject an invalid interface:
// RUN: not %target-build-swift -emit-library -enable-library-evolution -emit-module-interface -emit-module -swift-version 5 -o %t/MyModule.o -verify-emitted-module-interface -module-name MyModule -Xfrontend -debug-emit-invalid-swiftinterface-syntax %s 2>&1 | %FileCheck %s

// ...but not if verification is off.
// RUN: %target-build-swift -emit-library -enable-library-evolution -emit-module-interface -emit-module -swift-version 5 -o %t/MyModule.o -no-verify-emitted-module-interface -module-name MyModule -Xfrontend -debug-emit-invalid-swiftinterface-syntax %s

/// The verification can be downgraded to a warning using the env var.
// RUN: env SWIFT_FORCE_DOWNGRADE_VERIFICATION=MyModule %target-build-swift -emit-library -enable-library-evolution -emit-module-interface -emit-module -swift-version 5 -o %t/MyModule.o -verify-emitted-module-interface -module-name MyModule -Xfrontend -debug-emit-invalid-swiftinterface-syntax %s 2>&1 | %FileCheck --check-prefixes=CHECK-WARNING %s
// RUN: env SWIFT_FORCE_DOWNGRADE_VERIFICATION=SomeOtherModule,MyModule %target-build-swift -emit-library -enable-library-evolution -emit-module-interface -emit-module -swift-version 5 -o %t/MyModule.o -verify-emitted-module-interface -module-name MyModule -Xfrontend -debug-emit-invalid-swiftinterface-syntax %s 2>&1 | %FileCheck --check-prefixes=CHECK-WARNING %s
// RUN: env SWIFT_FORCE_DOWNGRADE_VERIFICATION=NotMyModule not %target-build-swift -emit-library -enable-library-evolution -emit-module-interface -emit-module -swift-version 5 -o %t/MyModule.o -verify-emitted-module-interface -module-name MyModule -Xfrontend -debug-emit-invalid-swiftinterface-syntax %s 2>&1 | %FileCheck %s

public struct MyStruct {}

// CHECK: MyModule.swiftinterface:{{[0-9]+}}:{{[0-9]+}}: error: no macro named '__debug_emit_invalid_swiftinterface_syntax__'
// CHECK: MyModule.swiftinterface:{{[0-9]+}}:{{[0-9]+}}: error: failed to verify module interface of 'MyModule' due to the errors above; the textual interface may be broken by project issues or a compiler bug

// CHECK-WARNING: MyModule.swiftinterface:{{[0-9]+}}:{{[0-9]+}}: warning: no macro named '__debug_emit_invalid_swiftinterface_syntax__'
