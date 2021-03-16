// RUN: %empty-directory(%t)

/// Expect warnings when building a public client.
// RUN: %target-swift-frontend -sdk %S/Inputs/public-private-sdk -typecheck -module-cache-path %t %s \
// RUN:   -F %S/Inputs/public-private-sdk/System/Library/PrivateFrameworks/ \
// RUN:   -enable-library-evolution -verify -D PUBLIC_IMPORTS

/// Expect no warnings when building a private client.
// RUN: %target-swift-frontend -sdk %S/Inputs/public-private-sdk -typecheck -module-cache-path %t %s \
// RUN:   -F %S/Inputs/public-private-sdk/System/Library/PrivateFrameworks/ \
// RUN:   -D PUBLIC_IMPORTS
#if PUBLIC_IMPORTS
import PublicSwift
import PrivateSwift // expected-warning{{private module 'PrivateSwift' is imported publicly from the public module 'main'}}
                    // expected-warning @-1 {{module 'PrivateSwift' was not compiled with library evolution support}}
import PublicClang
import PublicClang_Private // expected-warning{{private module 'PublicClang_Private' is imported publicly from the public module 'main'}}
import FullyPrivateClang // expected-warning{{private module 'FullyPrivateClang' is imported publicly from the public module 'main'}}

/// Expect no warnings with implementation-only imports.
// RUN: %target-swift-frontend -sdk %S/Inputs/public-private-sdk -typecheck -module-cache-path %t %s \
// RUN:   -F %S/Inputs/public-private-sdk/System/Library/PrivateFrameworks/ \
// RUN:   -enable-library-evolution -D IMPL_ONLY_IMPORTS
#elseif IMPL_ONLY_IMPORTS

@_implementationOnly import PrivateSwift
@_implementationOnly import PublicClang_Private
@_implementationOnly import FullyPrivateClang

#endif
