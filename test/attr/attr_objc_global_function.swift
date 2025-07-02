// RUN: %target-typecheck-verify-swift -enable-objc-interop \
// RUN:   -enable-experimental-feature CDecl

// REQUIRES: swift_feature_CDecl

@objc(cdecl_foo:) func foo(x: Int) -> Int { return x }

@objc("") // expected-error {{expected ')'}} expected-note {{to match this opening '('}}
// expected-error @-1 {{expected declaration}}
func emptyName(x: Int) -> Int { return x }

@objc(noBody)
func noBody() -> Int // expected-error{{expected '{' in body of function}}

@objc(missingParam) // expected-error {{@objc' method name provides names for 0 arguments, but method has one parameter}}
func missingParam(x: Int) -> Int { x }

@objc(property) // expected-error{{'@objc' can only be used with members of classes, '@objc' protocols, concrete extensions of classes and global functions}}
var property: Int

var computed: Int {
  @objc(get_computed) get { return 0 } // expected-error {{'@objc' can only be used with members of classes, '@objc' protocols, concrete extensions of classes and global functions}}
  @objc(set_computed) set { return } // expected-error {{'@objc' can only be used with members of classes, '@objc' protocols, concrete extensions of classes and global functions}}
}

struct SwiftStruct { var x, y: Int }
enum SwiftEnum { case A, B }
#if os(Windows) && (arch(x86_64) || arch(arm64))
@objc enum CEnum: Int32 { case A, B }
#else
@objc enum CEnum: Int { case A, B }
#endif

@objc(enum)
enum UnderscoreCDeclEnum: CInt { case A, B }

@objc(swiftStruct:)
func swiftStruct(x: SwiftStruct) {}

@objc(swiftEnum:)
func swiftEnum(x: SwiftEnum) {}

@objc(cEnum:)
func cEnum(x: CEnum) {}

class Foo {
  @objc(Foo_foo) // expected-error{{'@objc' method name provides names for 0 arguments, but method has one parameter}}
  func foo(x: Int) -> Int { return x }

  @objc(Foo_foo_2) // expected-error{{'@objc' method name provides names for 0 arguments, but method has one parameter}}
  static func foo(x: Int) -> Int { return x }

  @objc(Foo_init)
  init() {}

  @objc(Foo_deinit) // expected-error{{'@objc' deinitializer cannot have a name}}
  deinit {}
}

func hasNested() {
  @objc(nested)
  func nested() { }
}

// TODO: Handle error conventions in SILGen for toplevel functions.
@objc(throwing:)
func throwing() throws { }

@objc func swift_allocBox() {} // expected-warning {{symbol name 'swift_allocBox' is reserved for the Swift runtime and cannot be directly referenced without causing unpredictable behavior; this will become an error}}
@objc(swift_allocObject) func swift_allocObject_renamed() {} // expected-warning {{symbol name 'swift_allocObject' is reserved for the Swift runtime and cannot be directly referenced without causing unpredictable behavior; this will become an error}}
