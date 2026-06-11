public enum _ObservationPolyfillLocals {
  @TaskLocal public static var skipObservationPolyfillChecking = false

  #if DEBUG
    @available(iOS, deprecated: 17)
    @available(macOS, deprecated: 14)
    @available(watchOS, deprecated: 10)
    @available(tvOS, deprecated: 17)
    @TaskLocal public static var isInObservationTracking = false
  #endif
}
