/// Simulate typical modularization issues using Swift modules.
// RUN: %empty-directory(%t)
// RUN: split-file %s %t

/// Compile two library modules A and B, and a client.
// RUN: %target-swift-frontend %t/LibOriginal.swift -emit-module-path %t/A.swiftmodule -module-name A
// RUN: %target-swift-frontend %t/Empty.swift -emit-module-path %t/B.swiftmodule -module-name B
// RUN: %target-swift-frontend %t/Client.swift -emit-module-path %t/Client.swiftmodule -module-name Client -I %t

/// Move MyType from A to B.
// RUN: %target-swift-frontend %t/Empty.swift -emit-module-path %t/A.swiftmodule -module-name A
// RUN: %target-swift-frontend %t/LibOriginal.swift -emit-module-path %t/B.swiftmodule -module-name B
// RUN: not %target-swift-frontend -emit-sil %t/Client.swiftmodule -module-name Client -I %t 2>&1 \
// RUN:   | %FileCheck --check-prefixes CHECK,CHECK-MOVED %s
// CHECK-MOVED: <unknown>:0: error: module reference to top-level 'MyType' broken by a context change, was found in 'A' when building 'Client', but now a candidate is found only in 'B'. Audit related headers or uninstall SDK roots.

/// Change MyType into a function.
// RUN: %target-swift-frontend %t/LibTypeChanged.swift -emit-module-path %t/A.swiftmodule -module-name A
// RUN: %target-swift-frontend %t/Empty.swift -emit-module-path %t/B.swiftmodule -module-name B
// RUN: not %target-swift-frontend -emit-sil %t/Client.swiftmodule -module-name Client -I %t 2>&1 \
// RUN:   | %FileCheck --check-prefixes CHECK,CHECK-TYPE-CHANGED %s
// CHECK-TYPE-CHANGED: <unknown>:0: error: module reference to top-level 'MyType' broken by a context change, its type changed since building 'Client', it was in 'A' now found in 'A'. Ensure Swift language version match between modules or uninstall SDK roots.

/// Remove MyType from all imported modules.
// RUN: %target-swift-frontend %t/Empty.swift -emit-module-path %t/A.swiftmodule -module-name A
// RUN: %target-swift-frontend %t/Empty.swift -emit-module-path %t/B.swiftmodule -module-name B
// RUN: not %target-swift-frontend -emit-sil %t/Client.swiftmodule -module-name Client -I %t 2>&1 \
// RUN:   | %FileCheck --check-prefixes CHECK,CHECK-NOT-FOUND %s
// CHECK-NOT-FOUND: <unknown>:0: error: module reference to top-level 'MyType' broken by a context change, module 'Client' references 'MyType' in 'A', but it cannot be found in this build. Audit related headers or uninstall SDK roots.
// CHECK: <unknown>:0: note: could not deserialize extension

//--- Empty.swift
//--- LibOriginal.swift
public struct MyType {
    public init() {}
}

//--- LibTypeChanged.swift
/// Make it a function to fail filtering.
public func MyType() {}

//--- Client.swift
import A
import B

public protocol Proto {}
extension MyType : Proto {}

@available(SwiftStdlib 5.1, *)
public func foo() -> some Proto { return MyType() }
