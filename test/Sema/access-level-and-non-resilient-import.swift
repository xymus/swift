/// Check diagnostics on a resilient modules importing publicly a
/// a non-resilient module.

// RUN: %empty-directory(%t)
// RUN: split-file --leading-lines %s %t

/// Build the libraries.
// RUN: %target-swift-frontend -emit-module %t/DefaultLib.swift -o %t
// RUN: %target-swift-frontend -emit-module %t/PublicLib.swift -o %t
// RUN: %target-swift-frontend -emit-module %t/PackageLib.swift -o %t
// RUN: %target-swift-frontend -emit-module %t/InternalLib.swift -o %t
// RUN: %target-swift-frontend -emit-module %t/FileprivateLib.swift -o %t
// RUN: %target-swift-frontend -emit-module %t/PrivateLib.swift -o %t

/// A resilient client with library-level api will error on public imports.
// RUN: %target-swift-frontend -typecheck %t/Client_DefaultPublic.swift -I %t \
// RUN:   -enable-library-evolution -swift-version 6 \
// RUN:   -library-level api -package-name pkg -verify
// RUN: %target-swift-frontend -typecheck %t/Client_DefaultInternal.swift -I %t \
// RUN:   -enable-library-evolution -swift-version 6 \
// RUN:   -enable-upcoming-feature InternalImportsByDefault \
// RUN:   -library-level api -package-name pkg -verify

/// A non-resilient client doesn't complain.
// RUN: %target-swift-frontend -typecheck %t/Client_DefaultPublic.swift -I %t \
// RUN:   -swift-version 6 \
// RUN:   -enable-experimental-feature AccessLevelOnImport \
// RUN:   -package-name pkg
// RUN: %target-swift-frontend -typecheck %t/Client_DefaultInternal.swift -I %t \
// RUN:   -swift-version 6 \
// RUN:   -enable-upcoming-feature InternalImportsByDefault \
// RUN:   -package-name pkg

// Any library-level other than API only warns.
// RUN: %target-swift-frontend -typecheck %t/Client_DefaultPublic_Warn.swift -I %t \
// RUN:   -enable-library-evolution -swift-version 6 \
// RUN:   -library-level spi -package-name pkg -verify
// RUN: %target-swift-frontend -typecheck %t/Client_DefaultPublic_Warn.swift -I %t \
// RUN:   -enable-library-evolution -swift-version 6 \
// RUN:   -library-level other -package-name pkg -verify
// RUN: %target-swift-frontend -typecheck %t/Client_DefaultPublic_Warn.swift -I %t \
// RUN:   -enable-library-evolution -swift-version 6 \
// RUN:   -package-name pkg -verify

// RUN: %target-swift-frontend -typecheck %t/Client_DefaultInternal_Warn.swift -I %t \
// RUN:   -enable-library-evolution -swift-version 5 \
// RUN:   -enable-upcoming-feature InternalImportsByDefault \
// RUN:   -library-level spi -package-name pkg -verify
// RUN: %target-swift-frontend -typecheck %t/Client_DefaultInternal_Warn.swift -I %t \
// RUN:   -enable-library-evolution -swift-version 5 \
// RUN:   -enable-upcoming-feature InternalImportsByDefault \
// RUN:   -library-level other -package-name pkg -verify
// RUN: %target-swift-frontend -typecheck %t/Client_DefaultInternal_Warn.swift -I %t \
// RUN:   -enable-library-evolution -swift-version 5 \
// RUN:   -enable-upcoming-feature InternalImportsByDefault \
// RUN:   -package-name pkg -verify

//--- DefaultLib.swift
//--- PublicLib.swift
//--- PackageLib.swift
//--- InternalLib.swift
//--- FileprivateLib.swift
//--- PrivateLib.swift

//--- Client_DefaultPublic.swift

import DefaultLib // expected-error {{module 'DefaultLib' was not compiled with library evolution support; using it means binary compatibility for 'Client_DefaultPublic' can't be guaranteed}} {{1-1=internal }}
public import PublicLib // expected-error {{module 'PublicLib' was not compiled with library evolution support; using it means binary compatibility for 'Client_DefaultPublic' can't be guaranteed}} {{1-7=internal}}
// expected-warning @-1 {{public import of 'PublicLib' was not used in public declarations or inlinable code}}
package import PackageLib
// expected-warning @-1 {{package import of 'PackageLib' was not used in package declarations}}
internal import InternalLib
fileprivate import FileprivateLib
private import PrivateLib

//--- Client_DefaultPublic_Warn.swift

import DefaultLib // expected-warning {{module 'DefaultLib' was not compiled with library evolution support; using it means binary compatibility for 'Client_DefaultPublic_Warn' can't be guaranteed}} {{1-1=internal }}
public import PublicLib // expected-warning {{module 'PublicLib' was not compiled with library evolution support; using it means binary compatibility for 'Client_DefaultPublic_Warn' can't be guaranteed}} {{1-7=internal}}
// expected-warning @-1 {{public import of 'PublicLib' was not used in public declarations or inlinable code}}
package import PackageLib
// expected-warning @-1 {{package import of 'PackageLib' was not used in package declarations}}
internal import InternalLib
fileprivate import FileprivateLib
private import PrivateLib

//--- Client_DefaultInternal.swift

import DefaultLib
public import PublicLib // expected-error {{module 'PublicLib' was not compiled with library evolution support; using it means binary compatibility for 'Client_DefaultInternal' can't be guaranteed}} {{1-8=}}
// expected-warning @-1 {{public import of 'PublicLib' was not used in public declarations or inlinable code}}
package import PackageLib
// expected-warning @-1 {{package import of 'PackageLib' was not used in package declarations}}
internal import InternalLib
fileprivate import FileprivateLib
private import PrivateLib

//--- Client_DefaultInternal_Warn.swift

import DefaultLib
public import PublicLib // expected-warning {{module 'PublicLib' was not compiled with library evolution support; using it means binary compatibility for 'Client_DefaultInternal_Warn' can't be guaranteed}} {{1-8=}}
// expected-warning @-1 {{public import of 'PublicLib' was not used in public declarations or inlinable code}}
package import PackageLib
// expected-warning @-1 {{package import of 'PackageLib' was not used in package declarations}}
internal import InternalLib
fileprivate import FileprivateLib
private import PrivateLib
