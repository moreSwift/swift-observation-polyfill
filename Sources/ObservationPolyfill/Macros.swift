//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if $Macros && hasAttribute(attached)
  import ObservationPolyfillCore
  #if canImport(Observation)
    import Observation
  #endif

  /// Defines and implements conformance of the Observable protocol.
  ///
  /// > Important: This is a back-port of Swift's `@Observation.Observable` macro.
  ///
  /// This macro adds observation support to a custom type and conforms the type
  /// to the ``ObservationPolyfill/Observable`` protocol. For example, the following code
  /// applies the `Observable` macro to the type `Car` making it perceptible:
  ///
  ///     @ObservationPolyfill.Observable
  ///     class Car {
  ///        var name: String = ""
  ///        var needsRepairs: Bool = false
  ///
  ///        init(name: String, needsRepairs: Bool = false) {
  ///            self.name = name
  ///            self.needsRepairs = needsRepairs
  ///        }
  ///     }
  @available(iOS, deprecated: 26, renamed: "Observation.Observable")
  @available(macOS, deprecated: 26, renamed: "Observation.Observable")
  @available(watchOS, deprecated: 26, renamed: "Observation.Observable")
  @available(tvOS, deprecated: 26, renamed: "Observation.Observable")
  @attached(
    member,
    names: named(_$observationPolyfillRegistrar),
    named(access),
    named(withMutation),
    named(shouldNotifyObservers)
  )
  @attached(memberAttribute)
  @attached(extension, conformances: ObservationPolyfill.Observable)
  public macro Observable() =
    #externalMacro(module: "ObservationPolyfillMacros", type: "ObservableMacro")

  /// Synthesizes a property for accessors.
  ///
  /// > Important: This is a back-port of Swift's `@ObservationTracked` macro.
  ///
  /// The ``ObservationPolyfill`` module uses this macro. Its use outside of the
  /// framework isn't necessary.
  @available(iOS, deprecated: 26, renamed: "ObservationTracked")
  @available(macOS, deprecated: 26, renamed: "ObservationTracked")
  @available(watchOS, deprecated: 26, renamed: "ObservationTracked")
  @available(tvOS, deprecated: 26, renamed: "ObservationTracked")
  @attached(accessor, names: named(init), named(get), named(set), named(_modify))
  @attached(peer, names: prefixed(_))
  public macro ObservationTracked() =
    #externalMacro(module: "ObservationPolyfillMacros", type: "ObservationTrackedMacro")

  /// Disables observation tracking of a property.
  ///
  /// > Important: This is a back-port of Swift's `@ObservationIgnored` macro.
  ///
  /// By default, an object can perceive any property of a perceptible type that
  /// is accessible to the perceiving object. To prevent observation of an
  /// accessible property, attach the `ObservationIgnored` macro to the property.
  @available(iOS, deprecated: 26, renamed: "ObservationIgnored")
  @available(macOS, deprecated: 26, renamed: "ObservationIgnored")
  @available(watchOS, deprecated: 26, renamed: "ObservationIgnored")
  @available(tvOS, deprecated: 26, renamed: "ObservationIgnored")
  @attached(accessor, names: named(willSet))
  public macro ObservationIgnored() =
    #externalMacro(module: "ObservationPolyfillMacros", type: "ObservationIgnoredMacro")

#endif
