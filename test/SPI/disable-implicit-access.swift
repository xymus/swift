// RUN: %empty-directory(%t)
// RUN: split-file %s %t

/// Compile two frameworks into the SDK.
// RUN: %target-swift-frontend -emit-module -module-name PublicLib \
// RUN:   %t/sdk/System/Library/Frameworks/PublicLib.framework/Modules/PublicLib.swiftmodule/source.swift \
// RUN:   -o %t/sdk/System/Library/Frameworks/PublicLib.framework/Modules/PublicLib.swiftmodule/%target-swiftmodule-name \
// RUN:   -enable-library-evolution -swift-version 6
// RUN: %target-swift-frontend -emit-module -module-name PrivateLib \
// RUN:   %t/sdk/System/Library/PrivateFrameworks/PrivateLib.framework/Modules/PrivateLib.swiftmodule/source.swift \
// RUN:   -o %t/sdk/System/Library/PrivateFrameworks/PrivateLib.framework/Modules/PrivateLib.swiftmodule/%target-swiftmodule-name \
// RUN:   -enable-library-evolution -swift-version 6

/// Build fine without -disable-implicit-spi.
// RUN: %target-swift-frontend -typecheck %t/Client.swift \
// RUN:   -sdk %t/sdk -F %t/sdk/System/Library/PrivateFrameworks \
// RUN:   -swift-version 6

/// With -disable-implicit-spi, some SPIs are hidden.
// RUN: %target-swift-frontend -typecheck -verify %t/Client.swift \
// RUN:   -sdk %t/sdk -F %t/sdk/System/Library/PrivateFrameworks \
// RUN:   -swift-version 6 -disable-implicit-spi

// REQUIRES: VENDOR=apple

//--- sdk/System/Library/Frameworks/PublicLib.framework/Modules/PublicLib.swiftmodule/source.swift

@_spi(S) public func publicSPIFunc() {}
@_spi(_) public func publicImplicitSPIFunc() {}
public func publicModuleFunc() {}

public struct PublicStruct {
  public init() {}
}

//--- sdk/System/Library/PrivateFrameworks/PrivateLib.framework/Modules/PrivateLib.swiftmodule/source.swift

@_spi(S) public func privateSPIFunc() {}
@_spi(_) public func privateImplicitSPIFunc() {}
public func privateModuleFunc_DontSuggestTypo() {}

public struct PrivateStruct {
  public init() {}
}

//--- Client.swift

@_spi(S) import PublicLib
@_spi(S) import PrivateLib

func user() {
  publicSPIFunc()
  publicImplicitSPIFunc() // expected-error {{cannot find 'publicImplicitSPIFunc' in scope}}
  publicModuleFunc()
  let _: PublicStruct = PublicStruct()

  privateSPIFunc()
  privateImplicitSPIFunc() // expected-error {{cannot find 'privateImplicitSPIFunc' in scope}}
  privateModuleFunc_DontSuggestTypo() // expected-error {{cannot find 'privateModuleFunc_DontSuggestTypo' in scope}}
  let _: PrivateStruct = PrivateStruct()
  // expected-error @-1 {{cannot find 'PrivateStruct' in scope}}
  // expected-error @-2 {{cannot find type 'PrivateStruct' in scope}}
}
