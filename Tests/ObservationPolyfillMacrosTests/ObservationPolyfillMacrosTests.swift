#if os(macOS)
  import MacroTesting
  import ObservationPolyfillMacros
  import SnapshotTesting
  import Testing

  @Suite(
    .macros(
      [
        "ObservationPolyfill.Observable": ObservableMacro.self,
        "ObservationPolyfill.ObservationTracked": ObservationTrackedMacro.self,
        "ObservationPolyfill.ObservationIgnored": ObservationIgnoredMacro.self,
      ],
      record: .failed
    )
  )
  struct ObservableMacroTests {
    @Test func basics() {
      assertMacro {
        """
        @ObservationPolyfill.Observable
        class Feature {
          var count = 0
        }
        """
      } expansion: {
        #"""
        class Feature {
          var count {
            @storageRestrictions(initializes: _count)
            init(initialValue) {
              _count = initialValue
            }
            get {
              _$observationPolyfillRegistrar.access(self, keyPath: \.count)
              return _count
            }
            set {
              guard shouldNotifyObservers(_count, newValue) else {
                _count = newValue
                return
              }
              withMutation(keyPath: \.count) {
                _count = newValue
              }
            }
            _modify {
              access(keyPath: \.count)
              _$observationPolyfillRegistrar.willSet(self, keyPath: \.count)
              defer {
                _$observationPolyfillRegistrar.didSet(self, keyPath: \.count)
              }
              yield &_count
            }
          }

          private  var _count  = 0

          private let _$observationPolyfillRegistrar = ObservationPolyfill.ObservationPolyfillRegistrar()

          internal nonisolated func access<__macro_local_6MemberfMu_>(
            keyPath: KeyPath<Feature, __macro_local_6MemberfMu_>
          ) {
            _$observationPolyfillRegistrar.access(self, keyPath: keyPath)
          }

          internal nonisolated func withMutation<__macro_local_6MemberfMu0_, __macro_local_14MutationResultfMu_>(
            keyPath: KeyPath<Feature, __macro_local_6MemberfMu0_>,
            _ mutation: () throws -> __macro_local_14MutationResultfMu_
          ) rethrows -> __macro_local_14MutationResultfMu_ {
            try _$observationPolyfillRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
          }

          private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu1_>(_ lhs: __macro_local_6MemberfMu1_, _ rhs: __macro_local_6MemberfMu1_) -> Bool {
            true
          }

          private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu2_: Equatable>(_ lhs: __macro_local_6MemberfMu2_, _ rhs: __macro_local_6MemberfMu2_) -> Bool {
            lhs != rhs
          }

          private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu3_: AnyObject>(_ lhs: __macro_local_6MemberfMu3_, _ rhs: __macro_local_6MemberfMu3_) -> Bool {
            lhs !== rhs
          }

          private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu4_: Equatable & AnyObject>(_ lhs: __macro_local_6MemberfMu4_, _ rhs: __macro_local_6MemberfMu4_) -> Bool {
            lhs != rhs
          }
        }
        """#
      }
    }
  }
#endif
