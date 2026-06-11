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


/// A type that emits notifications to perceivers when underlying data changes.
///
/// > Important: This is a back-port of Swift's `Observable` protocol.
///
/// Conforming to this protocol signals to other APIs that the type supports
/// observation. However, applying the `Observable` protocol by itself to a
/// type doesn't add observation functionality to the type. Instead, always use
/// the ``ObservationPolyfill/Observable()`` macro when adding observation
/// support to a type.
@available(iOS, deprecated: 26, renamed: "Observation.Observable")
@available(macOS, deprecated: 26, renamed: "Observation.Observable")
@available(watchOS, deprecated: 26, renamed: "Observation.Observable")
@available(tvOS, deprecated: 26, renamed: "Observation.Observable")
public protocol Observable { }
