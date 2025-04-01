// RUN: %target-typecheck-verify-swift -enable-objc-interop
// RUN: %target-swift-frontend -typecheck %s -enable-objc-interop \
// RUN:   -enable-experimental-feature CDeclOfficial

@cdecl("cdecl_foo") func foo(x: Int) -> Int { return x } // expected-error {{@cdecl requires '-enable-experimental-feature CDeclOfficial'}}

var computed: Int {
  @cdecl("get_computed") get { return 0 } // expected-error {{@cdecl requires '-enable-experimental-feature CDeclOfficial'}}
  @cdecl("set_computed") set { return } // expected-error {{@cdecl requires '-enable-experimental-feature CDeclOfficial'}}
}
