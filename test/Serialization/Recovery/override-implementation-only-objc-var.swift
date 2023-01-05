// RUN: %empty-directory(%t)
// RUN: %empty-directory(%t/src)
// RUN: %empty-directory(%t/sdk)
// RUN: split-file %s %t/src
// RUN: mv %t/src/module.modulemap %t/src/IPIModule.h %t/sdk

// REQUIRES: asserts
// REQUIRES: objc_interop

// RUN: %target-swift-frontend -emit-module %t/src/IPIModule.swift \
// RUN:   -module-name IPIModule -swift-version 5 -I %t/sdk \
// RUN:   -enable-library-evolution \
// RUN:   -emit-module-path %t/sdk/IPIModule.swiftmodule \
// RUN:   -emit-module-interface-path %t/sdk/IPIModule.swiftinterface \
// RUN:   -emit-private-module-interface-path %t/sdk/IPIModule.private.swiftinterface
// RUN: %target-swift-typecheck-module-from-interface(%t/sdk/IPIModule.swiftinterface) -I %t/sdk
// RUN: %target-swift-typecheck-module-from-interface(%t/sdk/IPIModule.private.swiftinterface) -module-name IPIModule -I %t/sdk

// RUN: %target-swift-frontend -emit-module %t/src/PublicModule.swift \
// RUN:   -module-name PublicModule -swift-version 5 -I %t/sdk \
// RUN:   -enable-library-evolution \
// RUN:   -emit-module-path %t/sdk/PublicModule.swiftmodule \
// RUN:   -emit-module-interface-path %t/sdk/PublicModule.swiftinterface \
// RUN:   -emit-private-module-interface-path %t/sdk/PublicModule.private.swiftinterface
// RUN: %target-swift-typecheck-module-from-interface(%t/sdk/PublicModule.swiftinterface) -I %t/sdk
// RUN: %target-swift-typecheck-module-from-interface(%t/sdk/PublicModule.private.swiftinterface) -module-name PublicModule -I %t/sdk

// RUN: %target-swift-frontend -typecheck %t/src/Client.swift \
// RUN:   -module-name Client -I %t/sdk \
// RUN:   -Xllvm -debug-only=Serialization -verify

//--- module.modulemap
module IPIModule {
    header "IPIModule.h"
}

//--- IPIModule.h
#include <Foundation/Foundation.h>

@interface ObjCType : NSObject

@property (readonly, copy) NSString *name;

@end

//--- IPIModule.swift
@_exported import IPIModule

public struct Bar2 {
    public init() {}
    private var priv2 = 12
    public func privFunc() {}
}

//--- PublicModule.swift
@_implementationOnly import IPIModule
import Foundation

@objc
class SwiftType: ObjCType {
    @_implementationOnly
    override var name: String? { return "asdf" }
}

public struct Bar {
    private var priv = 12
}

//--- Client.swift
import PublicModule

func foo(obj: AnyObject) {
    obj.name // expected-error {{value of type 'AnyObject' has no member 'name'}}
}
