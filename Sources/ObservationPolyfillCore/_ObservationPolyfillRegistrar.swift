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

@available(iOS, deprecated: 17, renamed: "Observation.ObservationRegistrar")
@available(macOS, deprecated: 14, renamed: "Observation.ObservationRegistrar")
@available(watchOS, deprecated: 10, renamed: "Observation.ObservationRegistrar")
@available(tvOS, deprecated: 17, renamed: "Observation.ObservationRegistrar")
@usableFromInline
internal struct _ObservationPolyfillRegistrar: Sendable {
  internal class ValueObservationPolyfillStorage {
    func emit<Element>(_ element: Element) -> Bool { return false }
    func cancel() { }
  }
  
  private struct ValuesPerceiver {
    private let storage: ValueObservationPolyfillStorage
    
    internal init(storage: ValueObservationPolyfillStorage) {
      self.storage = storage
    }
    
    internal func emit<Element>(_ element: Element) -> Bool {
      storage.emit(element)
    }
    
    internal func cancel() {
      storage.cancel()
    }
  }
  
  private struct State: @unchecked Sendable {
    private enum ObservationPolyfillKind {
      case willSetTracking(@Sendable (AnyKeyPath) -> Void)
      case didSetTracking(@Sendable (AnyKeyPath) -> Void)
    }
    
    private struct ObservationPolyfill {
      private var kind: ObservationPolyfillKind
      internal var properties: Set<AnyKeyPath>
      
      internal init(kind: ObservationPolyfillKind, properties: Set<AnyKeyPath>) {
        self.kind = kind
        self.properties = properties
      }
      
      var willSetTracker: (@Sendable (AnyKeyPath) -> Void)? {
        switch kind {
        case .willSetTracking(let tracker):
          return tracker
        default:
          return nil
        }
      }

      var didSetTracker: (@Sendable (AnyKeyPath) -> Void)? {
        switch kind {
        case .didSetTracking(let tracker):
          return tracker
        default:
          return nil
        }
      }
    }
    
    private var id = 0
    private var observations = [Int : ObservationPolyfill]()
    private var lookups = [AnyKeyPath : Set<Int>]()
    
    internal mutating func generateId() -> Int {
      defer { id &+= 1 }
      return id
    }
    
    internal mutating func registerTracking(for properties: Set<AnyKeyPath>, willSet perceiver: @Sendable @escaping (AnyKeyPath) -> Void) -> Int {
      let id = generateId()
      observations[id] = ObservationPolyfill(kind: .willSetTracking(perceiver), properties: properties)
      for keyPath in properties {
        lookups[keyPath, default: []].insert(id)
      }
      return id
    }

    internal mutating func registerTracking(for properties: Set<AnyKeyPath>, didSet perceiver: @Sendable @escaping (AnyKeyPath) -> Void) -> Int {
      let id = generateId()
      observations[id] = ObservationPolyfill(kind: .didSetTracking(perceiver), properties: properties)
      for keyPath in properties {
        lookups[keyPath, default: []].insert(id)
      }
      return id
    }
    
    internal mutating func cancel(_ id: Int) {
      if let observation = observations.removeValue(forKey: id) {
        for keyPath in observation.properties {
          if let index = lookups.index(forKey: keyPath) {
            lookups.values[index].remove(id)
            if lookups.values[index].isEmpty {
              lookups.remove(at: index)
            }
          }
        }
      }
    }

    internal mutating func cancelAll() {
      observations.removeAll()
      lookups.removeAll()
    }
    
    internal mutating func willSet(keyPath: AnyKeyPath) -> [@Sendable (AnyKeyPath) -> Void] {
      var trackers = [@Sendable (AnyKeyPath) -> Void]()
      if let ids = lookups[keyPath] {
        for id in ids {
          if let tracker = observations[id]?.willSetTracker {
            trackers.append(tracker)
          }
        }
      }
      return trackers
    }
    
    internal mutating func didSet<Subject: Observable, Member>(keyPath: KeyPath<Subject, Member>) -> [@Sendable (AnyKeyPath) -> Void] {
      var trackers = [@Sendable (AnyKeyPath) -> Void]()
      if let ids = lookups[keyPath] {
        for id in ids {
          if let tracker = observations[id]?.didSetTracker {
            trackers.append(tracker)
          }
        }
      }
      return trackers
    }
  }
  
  internal struct Context: Sendable {
    private let state = _ManagedCriticalState(State())
    
    internal var id: ObjectIdentifier { state.id }
    
    internal func registerTracking(for properties: Set<AnyKeyPath>, willSet perceiver: @Sendable @escaping (AnyKeyPath) -> Void) -> Int {
      state.withCriticalRegion { $0.registerTracking(for: properties, willSet: perceiver) }
    }

    internal func registerTracking(for properties: Set<AnyKeyPath>, didSet perceiver: @Sendable @escaping (AnyKeyPath) -> Void) -> Int {
      state.withCriticalRegion { $0.registerTracking(for: properties, didSet: perceiver) }
    }
    
    internal func cancel(_ id: Int) {
      state.withCriticalRegion { $0.cancel(id) }
    }

    internal func cancelAll() {
      state.withCriticalRegion { $0.cancelAll() }
    }

    internal func willSet<Subject: Observable, Member>(
       _ subject: Subject,
       keyPath: KeyPath<Subject, Member>
    ) {
      let tracking = state.withCriticalRegion { $0.willSet(keyPath: keyPath) }
      for action in tracking {
        action(keyPath)
      }
    }
    
    internal func didSet<Subject: Observable, Member>(
      _ subject: Subject,
      keyPath: KeyPath<Subject, Member>
    ) {
      let tracking = state.withCriticalRegion { $0.didSet(keyPath: keyPath) }
      for action in tracking {
        action(keyPath)
      }
    }
  }

  private final class Extent: @unchecked Sendable {
    let context = Context()

    init() {
    }

    deinit {
      context.cancelAll()
    }
  }
  
  internal var context: Context {
    return extent.context
  }
  
  private var extent = Extent()

  /// Creates an instance of the observation registrar.
  ///
  /// You don't need to create an instance of
  /// ``ObservationPolyfill/ObservationPolyfillRegistrar`` when using the
  /// ``ObservationPolyfill/Observable()`` macro to indicate perceptibility
  /// of a type.
  public init() {
  }

  /// Registers access to a specific property for observation.
  ///
  /// - Parameters:
  ///   - subject: An instance of a perceptible type.
  ///   - keyPath: The key path of a perceived property.
  public func access<Subject: Observable, Member>(
      _ subject: Subject,
      keyPath: KeyPath<Subject, Member>
  ) {
    if let trackingPtr = _ThreadLocal.value?
      .assumingMemoryBound(to: ObservationTracking._AccessList?.self) {
      if trackingPtr.pointee == nil {
        trackingPtr.pointee = ObservationTracking._AccessList()
      }
      trackingPtr.pointee?.addAccess(keyPath: keyPath, context: context)
    }
  }
  
  /// A property observation called before setting the value of the subject.
  ///
  /// - Parameters:
  ///     - subject: An instance of a perceptible type.
  ///     - keyPath: The key path of a perceived property.
  public func willSet<Subject: Observable, Member>(
      _ subject: Subject,
      keyPath: KeyPath<Subject, Member>
  ) {
    context.willSet(subject, keyPath: keyPath)
  }

  /// A property observation called after setting the value of the subject.
  ///
  /// - Parameters:
  ///   - subject: An instance of a perceptible type.
  ///   - keyPath: The key path of a perceived property.
  public func didSet<Subject: Observable, Member>(
      _ subject: Subject,
      keyPath: KeyPath<Subject, Member>
  ) {
    context.didSet(subject, keyPath: keyPath)
  }
  
  /// Identifies mutations to the transactions registered for perceivers.
  ///
  /// This method calls ``willset(_:keypath:)`` before the mutation. Then it
  /// calls ``didset(_:keypath:)`` after the mutation.
  /// - Parameters:
  ///   - of: An instance of a perceptible type.
  ///   - keyPath: The key path of a perceived property.
  public func withMutation<Subject: Observable, Member, T>(
    of subject: Subject,
    keyPath: KeyPath<Subject, Member>,
    _ mutation: () throws -> T
  ) rethrows -> T {
    willSet(subject, keyPath: keyPath)
    defer { didSet(subject, keyPath: keyPath) }
    return try mutation()
  }
}

extension _ObservationPolyfillRegistrar: Codable {
  public init(from decoder: any Decoder) throws {
    self.init()
  }
  
  public func encode(to encoder: any Encoder) {
    // Don't encode a registrar's transient state.
  }
}

extension _ObservationPolyfillRegistrar: Hashable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    // A registrar should be ignored for the purposes of determining its
    // parent type's equality.
    return true
  }
  
  public func hash(into hasher: inout Hasher) {
    // Don't include a registrar's transient state in its parent type's
    // hash value.
  }
}
