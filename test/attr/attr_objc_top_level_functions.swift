// RUN: %target-typecheck-verify-swift -enable-objc-interop \
// RUN:   -enable-experimental-feature CDeclOfficial

@objc(cdecl_foo) func foo(x: Int) -> Int { return x }

@objc // expected-error{{symbol name cannot be empty}}
func emptyName(x: Int) -> Int { return x }

@objc("noBody")
func noBody(x: Int) -> Int // expected-error{{expected '{' in body of function}}

@objc("property") // expected-error{{may only be used on 'func' declarations}}
var property: Int

var computed: Int {
  @objc(get_computed) get { return 0 }
  @objc(set_computed) set { return }
}

struct SwiftStruct { var x, y: Int }
enum SwiftEnum { case A, B }
#if os(Windows) && (arch(x86_64) || arch(arm64))
@objc enum CEnum: Int32 { case A, B }
#else
@objc enum CEnum: Int { case A, B }
#endif

@objc("swiftStruct")
func swiftStruct(x: SwiftStruct) {} // expected-error{{cannot be represented}} expected-note{{Swift struct}}

@objc("swiftEnum")
func swiftEnum(x: SwiftEnum) {} // expected-error{{cannot be represented}} expected-note{{non-'@objc' enum}}

@objc("cEnum")
func cEnum(x: CEnum) {}

class Foo {
  @objc("Foo_foo") // expected-error{{can only be applied to global functions}}
  func foo(x: Int) -> Int { return x }

  @objc("Foo_foo_2") // expected-error{{can only be applied to global functions}}
  static func foo(x: Int) -> Int { return x }

  @objc("Foo_init") // expected-error{{may only be used on 'func'}}
  init() {}

  @objc("Foo_deinit") // expected-error{{may only be used on 'func'}}
  deinit {}
}

func hasNested() {
  @objc("nested") // expected-error{{can only be used in a non-local scope}}
  func nested() { }
}

// TODO: Handle error conventions in SILGen for toplevel functions.
@objc("throwing") // expected-error{{raising errors from @objc functions is not supported}}
func throwing() throws { }

// TODO: cdecl name collisions
