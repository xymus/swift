// RUN: %empty-directory(%t)
// RUN: split-file %s %t

/// Build the library.
// RUN: %target-swift-frontend -emit-module %t/Lib.swift -I %t \
// RUN:   -enable-library-evolution -swift-version 5 \
// RUN:   -emit-module-path %t/Lib.swiftmodule \
// RUN:   -emit-module-interface-path %t/Lib.swiftinterface

/// Build against the swiftmodule.
// RUN: %target-swift-frontend -typecheck %t/Client.swift -I %t \
// RUN:   -enable-deserialization-safety 2>&1

/// Build against the swiftinterface.
// RUN: rm %t/Lib.swiftmodule
// RUN: %target-swift-frontend -typecheck %t/Client.swift -I %t \
// RUN:   -enable-deserialization-safety 2>&1

//--- Lib.swift

open class Base {
  internal func privateMethod() -> Int {
    return 1
  }
}

open class Derived : Base {
  open override func privateMethod() -> Int {
    return super.privateMethod() + 1
  }
}

//--- Client.swift

import Lib

public class OtherFinalDerived : Derived {
  public override func privateMethod() -> Int {
    return super.privateMethod() + 1
  }
}
