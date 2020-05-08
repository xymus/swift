// Test limitations on SPI protocol requirements.

// RUN: %target-typecheck-verify-swift %s

// Reject SPI protocol requirements without a default implementation.
public protocol PublicProtoRejected {
  @_spi(Private) // expected-error{{protocol requirement 'reqWithoutDefault()' cannot be declared '@_spi' without an implementation in an unconstrainted protocol extension}}
  func reqWithoutDefault()

  @_spi(Private) // expected-error{{protocol requirement 'property' cannot be declared '@_spi' without an implementation in an unconstrainted protocol extension}}
  var property: Int { get set }

  @_spi(Private) // expected-error{{protocol requirement 'init()' cannot be declared '@_spi' without an implementation in an unconstrainted protocol extension}}
  init()

  @_spi(Private) // expected-error{{'@_spi' attribute cannot be applied to this declaration}}
  associatedtype T
}

extension PublicProtoRejected where Self : Equatable {
  func reqWithoutDefault() {
    // constrainted implementation
  }
}

// Accept SPI protocol requirements with an implementation.
public protocol PublicProto {
  @_spi(Private)
  func reqWithDefaultImplementation()

  @_spi(Private)
  var property: Int { get set }

  @_spi(Private)
  init()
}

extension PublicProto {
  @_spi(Private)
  public func reqWithDefaultImplementation() { }

  @_spi(Private)
  public var property: Int {
    get { return 42 }
    set { }
  }

  init() { }
}
