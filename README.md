# Swift RFC 2387

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-ietf/swift-rfc-2387/workflows/CI/badge.svg)](https://github.com/swift-ietf/swift-rfc-2387/actions/workflows/ci.yml)

Swift domain model of RFC 2387: The MIME Multipart/Related Content-type.

## Overview

RFC 2387 defines the multipart/related content type for compound objects made up of interrelated body parts, commonly used for HTML email with inline images referenced through Content-ID.

This package is a pure domain model: it models `RFC_2387.Related`, its `type`, `start` and `start-info` parameters, and the Content-ID identity of a body part. Wire parsing and serialization live in the in-package `RFC 2387 Coder` target behind the `Coder` trait (`RFC_2387.Related.Coder`, `RFC_2387.Related.coder(boundary:)` and the `Binary.Serializable` conformance); Apple Foundation bridging lives in the in-package `RFC 2387 Foundation Integration` target.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-ietf/swift-rfc-2387.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 2387", package: "swift-rfc-2387")
    ]
)
```

For the wire coder, request the `Coder` trait and depend on the `RFC 2387 Coder` product:

```swift
.package(url: "https://github.com/swift-ietf/swift-rfc-2387.git", branch: "main", traits: ["Coder"])
```

```swift
.product(name: "RFC 2387 Coder", package: "swift-rfc-2387")
```

## Quick Start

### Creating multipart/related with an inline image

```swift
import RFC_2045
import RFC_2046
import RFC_2387

let htmlPart = RFC_2046.BodyPart(
    contentType: .textHTMLUTF8,
    text: "<img src='cid:logo@example.com'>"
)

let imagePart = try RFC_2387.Related.inline(
    contentID: try RFC_2387.ContentID("logo@example.com"),
    contentType: .imagePNG,
    content: imageBytes
)

let related = try RFC_2387.Related(
    rootPart: htmlPart,
    relatedParts: [imagePart],
    boundary: try RFC_2046.Boundary("----=_Part_1")
)
```

### Reading the Content-ID of a part

```swift
let contentID: RFC_2387.ContentID? = imagePart.contentID
```

## Surface

```swift
extension RFC_2387 {
    public typealias ContentID = RFC_5322.Message.ID
}

extension RFC_2387 {
    public struct Related: Sendable, Hashable {
        public let multipart: RFC_2046.Multipart
        public let rootType: RFC_2045.ContentType
        public let start: ContentID?
        public let startInfo: String?

        public init(
            rootPart: RFC_2046.BodyPart,
            relatedParts: [RFC_2046.BodyPart],
            boundary: RFC_2046.Boundary,
            start: ContentID? = nil,
            startInfo: String? = nil
        ) throws(Error)
    }
}

// `start`, when given, must be the Content-ID of `rootPart`; a missing or different
// root Content-ID (including one that only a related part carries) throws
// `Error.startNotFound(start)`. Decoding (Foundation Integration) rejects JSON whose
// multipart, rootType, start and start-info disagree with a `DecodingError`.

extension RFC_2387.Related {
    public static func inline(
        contentID: RFC_2387.ContentID,
        contentType: RFC_2045.ContentType,
        transferEncoding: RFC_2045.ContentTransferEncoding = .base64,
        content: [Byte]
    ) throws(RFC_5322.Header.Value.Error) -> RFC_2046.BodyPart

    public static func multipart(
        rootPart: RFC_2046.BodyPart,
        relatedParts: [RFC_2046.BodyPart],
        boundary: RFC_2046.Boundary,
        rootType: RFC_2045.ContentType? = nil,
        start: RFC_2387.ContentID? = nil
    ) throws(RFC_2046.Multipart.Error) -> RFC_2046.Multipart
}

extension RFC_2046.BodyPart {
    public var contentID: RFC_2387.ContentID? { get }
}
```

## Related Packages

- [swift-rfc-2045](https://github.com/swift-ietf/swift-rfc-2045) - MIME Part One: Format of Internet Message Bodies
- [swift-rfc-2046](https://github.com/swift-ietf/swift-rfc-2046) - MIME Part Two: Media Types
- [swift-rfc-5322](https://github.com/swift-ietf/swift-rfc-5322) - Internet Message Format

## Requirements

- Swift 6.4+
- macOS 27+ / iOS 27+ / tvOS 27+ / watchOS 27+ / visionOS 27+

## License

This library is released under the Apache License 2.0. See [LICENSE](LICENSE.md) for details.
