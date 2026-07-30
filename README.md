# Swift RFC 2387

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-standards/swift-rfc-2387/workflows/CI/badge.svg)](https://github.com/swift-standards/swift-rfc-2387/actions/workflows/ci.yml)

Swift implementation of RFC 2387: The MIME Multipart/Related Content-type.

## Overview

RFC 2387 defines the multipart/related content type for compound objects made up of interrelated body parts. This package provides a pure Swift implementation for creating and managing multipart/related messages, commonly used for HTML emails with inline images where the HTML references images via Content-ID.

The package extends the RFC 2046 multipart implementation with support for related parts that reference each other through Content-ID headers, following the MIME multipart/related specification.

## Features

- **Multipart/Related Support**: Create compound documents with interrelated parts
- **Content-ID References**: Reference parts via Content-ID (e.g., `cid:logo@example.com` in HTML)
- **Inline Images**: Convenience methods for creating inline image parts
- **Root Type Parameter**: Specify the content type of the root part
- **Start Parameter**: Identify the root part by Content-ID
- **Custom Boundaries**: Support for custom boundary strings
- **Type-Safe API**: Extensions to RFC 2046 types for related content

## Installation

Add swift-rfc-2387 to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-ietf/swift-rfc-2387.git", from: "0.2.5")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 2387", package: "swift-rfc-2387")
    ]
)
```

## Quick Start

### Creating Multipart/Related with Inline Images

```swift
import RFC_2045
import RFC_2046
import RFC_2387

// Create HTML part with image reference
let htmlPart = RFC_2046.BodyPart(
    contentType: .textHTMLUTF8,
    text: "<img src='cid:logo@example.com'>"
)

// Create inline image with Content-ID
let imagePart = RFC_2046.BodyPart.inlineImage(
    contentID: "logo@example.com",
    contentType: RFC_2045.ContentType(type: "image", subtype: "png"),
    content: imageData
)

// Create multipart/related message
let related = try RFC_2046.Multipart.related(
    rootPart: htmlPart,
    relatedParts: [imagePart]
)
```

### Using the Related Subtype

```swift
import RFC_2046
import RFC_2387

// Access the related subtype constant
let subtype = RFC_2046.Multipart.Subtype.related
// Result: Multipart.Subtype with rawValue "related"
```

### Accessing Content-ID

```swift
let imagePart = RFC_2046.BodyPart.inlineImage(
    contentID: "logo@example.com",
    contentType: RFC_2045.ContentType(type: "image", subtype: "png"),
    content: imageData
)

// Access Content-ID header
let contentID = imagePart.contentID
// Result: "<logo@example.com>" (with angle brackets per RFC 2387)
```

## Usage

### Related Subtype Extension

```swift
extension RFC_2046.Multipart.Subtype {
    public static let related: Multipart.Subtype
}
```

### Inline Image Factory

```swift
extension RFC_2046.BodyPart {
    public static func inlineImage(
        contentID: String,
        contentType: RFC_2045.ContentType,
        transferEncoding: RFC_2045.ContentTransferEncoding = .base64,
        content: Data
    ) -> Self
}
```

### Content-ID Accessor

```swift
extension RFC_2046.BodyPart {
    public var contentID: String? { get }
}
```

### Creating Multipart/Related

```swift
extension RFC_2046.Multipart {
    public static func related(
        rootPart: RFC_2046.BodyPart,
        relatedParts: [RFC_2046.BodyPart],
        rootType: RFC_2045.ContentType? = nil,
        startContentID: String? = nil,
        boundary: String? = nil
    ) throws -> Self
}
```

### Advanced Examples

**Multiple inline images:**

```swift
let htmlContent = """
<html>
    <img src="cid:logo@example.com">
    <img src="cid:banner@example.com">
</html>
"""

let htmlPart = RFC_2046.BodyPart(
    contentType: .textHTMLUTF8,
    text: htmlContent
)

let logoPart = RFC_2046.BodyPart.inlineImage(
    contentID: "logo@example.com",
    contentType: RFC_2045.ContentType(type: "image", subtype: "png"),
    content: logoData
)

let bannerPart = RFC_2046.BodyPart.inlineImage(
    contentID: "banner@example.com",
    contentType: RFC_2045.ContentType(type: "image", subtype: "jpeg"),
    content: bannerData
)

let related = try RFC_2046.Multipart.related(
    rootPart: htmlPart,
    relatedParts: [logoPart, bannerPart]
)
```

**With root type parameter:**

```swift
let related = try RFC_2046.Multipart.related(
    rootPart: htmlPart,
    relatedParts: [imagePart],
    rootType: .textHTMLUTF8
)
```

**With start Content-ID parameter:**

```swift
let related = try RFC_2046.Multipart.related(
    rootPart: htmlPart,
    relatedParts: [],
    startContentID: "root@example.com"
)
```

**With custom boundary:**

```swift
let related = try RFC_2046.Multipart.related(
    rootPart: htmlPart,
    relatedParts: [imagePart],
    boundary: "CustomBoundary123"
)
```

## Related Packages

### Dependencies
- [swift-rfc-2045](https://github.com/swift-standards/swift-rfc-2045) - MIME Part One: Format of Internet Message Bodies
- [swift-rfc-2046](https://github.com/swift-standards/swift-rfc-2046) - MIME Part Two: Media Types

### Related Standards
- [swift-rfc-2388](https://github.com/swift-standards/swift-rfc-2388) - Returning Values from Forms: multipart/form-data

## Requirements

- Swift 6.0+
- macOS 14.0+ / iOS 17.0+ / tvOS 17.0+ / watchOS 10.0+

## License

This library is released under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
