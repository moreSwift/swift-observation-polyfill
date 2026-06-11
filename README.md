# ObservationPolyfill

`Observation` was introduced in iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, and watchOS 10.0. This polyfill brings the `Observation` API to iOS 13.0, macOS 10.15, tvOS 13.0, and watchOS 6.0.

The polyfill gets automatically generated from [swift-perception](https://github.com/pointfreeco/swift-perception) by the `make_polyfill.py` Python script which essentially renames a bunch of files and directories, and performs a series of carefully crafted find and replace operations.

This polyfill was created for [SwiftCrossUI](https://github.com/moreSwift/swift-cross-ui) which aims to recreate SwiftUI's API. The downside of using this polyfill over [swift-perception](https://github.com/pointfreeco/swift-perception) are that this polyfill's names clash with the real `Observation` APIs (by design). For SwiftCrossUI, that downside has been deemed worth it in order to match the SwiftUI experience closer.

## Important information

- Observable models produced using the polyfill are compatible with APIs that expect real `Observation.Observable` models. This is because the polyfilled macro generates a conformance to `Observation.Observable` when `Observation` is available.
- Observable models produced using `Observation` are not compatible with APIs that expect polyfilled `ObservationPolyfill.Observable` models.
- If your deployment target is lower than the platform version that brought the `Observation` library, then you can always use this polyfill's declarations unqualified (i.e. `@Observable` instead of `@ObservationPolyfill.Observable`), even if `Observation`/`SwiftUI` is in scope.
- `@Observable` unambiguously refers to the `ObservationPolyfill.Observable` macro as long as your deployment target is low enough that `Observation.Observable` isn't unconditionally available.
- Library developers relying on `ObservationPolyfill` must implement special handling and/or multiple copies of their APIs if they would like users to be able to use both polyfilled models and real `Observation.Observable` models with their library. This is because users with high enough deployment targets may want to be able to just use the first-party `Observation` module, especially when porting existing code from SwiftUI etc.
- When using `ObservationPolyfill` with SwiftUI and targeting pre-Observation OS versions, you must wrap each view body in the `WithObservationTracking` view to ensure that state tracking functions correctly. It's easy to forget to do this if you only test your app on the latest OS version, because your app will appear to work fine both with and without `WithObservationTracking`. This is the same way that things work when using [swift-perception](https://github.com/pointfreeco/swift-perception).

In short, there generally aren't any drawbacks to using `ObservationPolyfill` as an application developer, because polyfilled models are still compatible with regular `Observation` APIs, but as a library developer you have to take more care to support both `Observation` and `ObservationPolyfill`.
