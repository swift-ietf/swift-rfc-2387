// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-rfc-2387 open source project
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import ASCII_Serializer_Primitives
public import RFC_2045
public import RFC_2046
public import RFC_5322

extension RFC_2387 {
    /// RFC 2387 multipart/related message
    ///
    /// Represents a compound object with inter-related body parts.
    /// The root part is processed first; other parts are referenced via Content-ID.
    ///
    /// Per RFC 2387, multipart/related is used for compound objects where parts
    /// reference each other. The most common use case is HTML emails with inline
    /// images referenced via Content-ID.
    ///
    /// ## RFC 2387 Parameters
    ///
    /// - **type** (required): MIME media type of the root body part
    /// - **start** (optional): Content-ID of the root body part
    /// - **start-info** (optional): Additional information for root processing
    ///
    /// ## Example
    ///
    /// ```swift
    /// let htmlPart = RFC_2046.BodyPart(
    ///     headers: .init(contentType: .textHTMLUTF8),
    ///     content: .init("<img src='cid:logo@example.com'>")
    /// )
    ///
    /// let imagePart = RFC_2387.Related.inlineImage(
    ///     contentID: "logo@example.com",
    ///     contentType: RFC_2045.ContentType(type: "image", subtype: "png"),
    ///     content: imageData
    /// )
    ///
    /// let related = try RFC_2387.Related(
    ///     rootPart: htmlPart,
    ///     relatedParts: [imagePart],
    ///     boundary: try RFC_2046.Boundary("----=_Part_123")
    /// )
    /// ```
    ///
    /// ## See Also
    ///
    /// - [RFC 2387](https://www.rfc-editor.org/rfc/rfc2387)
    public struct Related: Sendable, Hashable, Codable {
        /// The underlying multipart message
        public let multipart: RFC_2046.Multipart

        /// Content-Type of the root part (RFC 2387 "type" parameter)
        public let rootType: RFC_2045.ContentType

        /// Content-ID of the root part (RFC 2387 "start" parameter)
        public let start: ContentID?

        /// Additional start information (RFC 2387 "start-info" parameter)
        public let startInfo: String?

        /// Creates a Related message WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 2387 validation.
        /// Only use for internal construction after validation.
        init(
            __unchecked: Void,
            multipart: RFC_2046.Multipart,
            rootType: RFC_2045.ContentType,
            start: ContentID?,
            startInfo: String?
        ) {
            self.multipart = multipart
            self.rootType = rootType
            self.start = start
            self.startInfo = startInfo
        }

        /// Creates a multipart/related message from parts
        ///
        /// - Parameters:
        ///   - rootPart: The root part (typically HTML)
        ///   - relatedParts: Parts referenced by the root (e.g., images)
        ///   - boundary: Boundary delimiter for the multipart message
        ///   - start: Content-ID of root part (optional, per RFC 2387)
        ///   - startInfo: Additional start information (optional)
        /// - Throws: `RFC_2387.Related.Error` if validation fails
        public init(
            rootPart: RFC_2046.BodyPart,
            relatedParts: [RFC_2046.BodyPart],
            boundary: RFC_2046.Boundary,
            start: ContentID? = nil,
            startInfo: String? = nil
        ) throws(Error) {
            let allParts = [rootPart] + relatedParts

            // RFC 2387: Root type is required
            guard let rootType = rootPart.contentType else {
                throw Error.missingRootType
            }

            // Build parameters for multipart
            // RFC 2387 parameters are quoted strings
            var parameters: [RFC_2045.Parameter.Name: String] = [:]
            parameters[.type] = #""\#(rootType.headerValue)""#
            if let start = start {
                // String(start) already produces "<id@domain>" with angle brackets
                parameters[.start] = #""\#(String(start))""#
            }
            if let startInfo = startInfo {
                parameters[.startInfo] = #""\#(startInfo)""#
            }

            let multipart: RFC_2046.Multipart
            do throws(RFC_2046.Multipart.Error) {
                multipart = try RFC_2046.Multipart(
                    subtype: .related,
                    parts: allParts,
                    boundary: boundary,
                    additionalParameters: parameters
                )
            } catch {
                throw Error.multipartError(error)
            }

            self.init(
                __unchecked: (),
                multipart: multipart,
                rootType: rootType,
                start: start,
                startInfo: startInfo
            )
        }
    }
}

// MARK: - BodyPart Extensions

extension RFC_2046.BodyPart {
    /// The Content-ID of this part, if specified
    ///
    /// Used in multipart/related for referencing parts (e.g., inline images).
    /// The value includes angle brackets per RFC 2387: `<id@example.com>`
    public var contentID: String? {
        headers[.contentId]
    }
}

// MARK: - Factory Methods

extension RFC_2387.Related {
    /// Creates an inline part with Content-ID for multipart/related
    ///
    /// Convenience for creating parts that can be referenced via `cid:` URLs.
    /// Common use cases include inline images, stylesheets, and fonts in HTML emails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let imagePart = try RFC_2387.Related.inline(
    ///     contentID: "logo@example.com",
    ///     contentType: .imagePNG,
    ///     content: imageData
    /// )
    ///
    /// // Reference in HTML: <img src="cid:logo@example.com">
    /// ```
    ///
    /// - Parameters:
    ///   - contentID: Content-ID for referencing via cid: URLs
    ///   - contentType: Content type of the inline part
    ///   - transferEncoding: Transfer encoding (defaults to base64 for binary data)
    ///   - content: Part content as bytes
    /// - Returns: BodyPart with Content-ID header set
    /// - Throws: If header creation fails
    public static func inline(
        contentID: RFC_2387.ContentID,
        contentType: RFC_2045.ContentType,
        transferEncoding: RFC_2045.ContentTransferEncoding = .base64,
        content: [Byte]
    ) -> RFC_2046.BodyPart {
        var headers = RFC_2046.BodyPart.Headers()
        headers.contentType = contentType
        headers.contentTransferEncoding = transferEncoding
        // String(contentID) produces "<id@domain>" with angle brackets per RFC 5322
        headers[.contentId] = String(contentID)

        return RFC_2046.BodyPart(
            headers: headers,
            content: RFC_2046.BodyPart.Content(content)
        )
    }

    /// Creates a multipart/related message
    ///
    /// Used for compound documents where parts reference each other.
    /// Common use case: HTML email with inline images referenced via Content-ID.
    ///
    /// **RFC 2387** - The MIME Multipart/Related Content-type
    ///
    /// ## Example
    ///
    /// ```swift
    /// let htmlPart = try RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<img src='cid:logo@example.com'>")
    ///
    /// let imagePart = try RFC_2387.Related.inline(
    ///     contentID: "logo@example.com",
    ///     contentType: .imagePNG,
    ///     content: imageData
    /// )
    ///
    /// let multipart = try RFC_2387.Related.multipart(
    ///     rootPart: htmlPart,
    ///     relatedParts: [imagePart],
    ///     boundary: try RFC_2046.Boundary("----=_Part_123")
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - rootPart: The root part (typically HTML)
    ///   - relatedParts: Parts referenced by the root (e.g., images)
    ///   - boundary: Boundary delimiter for the multipart message
    ///   - rootType: Content-Type of root part (optional, auto-detected from rootPart)
    ///   - start: Content-ID of root part (optional, per RFC 2387)
    /// - Throws: `RFC_2046.Multipart.Error` if validation fails
    /// - Returns: Configured multipart/related message
    public static func multipart(
        rootPart: RFC_2046.BodyPart,
        relatedParts: [RFC_2046.BodyPart],
        boundary: RFC_2046.Boundary,
        rootType: RFC_2045.ContentType? = nil,
        start: RFC_2387.ContentID? = nil
    ) throws(RFC_2046.Multipart.Error) -> RFC_2046.Multipart {
        let allParts = [rootPart] + relatedParts

        // RFC 2387: Auto-detect type from root part if not provided
        let detectedRootType = rootType ?? rootPart.contentType

        // Build parameters (RFC 2387 parameters are quoted strings)
        var parameters: [RFC_2045.Parameter.Name: String] = [:]
        if let type = detectedRootType {
            parameters[.type] = #""\#(type.headerValue)""#
        }
        if let start = start {
            // String(start) produces "<id@domain>" with angle brackets
            parameters[.start] = #""\#(String(start))""#
        }

        return try RFC_2046.Multipart(
            subtype: .related,
            parts: allParts,
            boundary: boundary,
            additionalParameters: parameters
        )
    }
}

// MARK: - Parameter Name Extensions

extension RFC_2045.Parameter.Name {
    /// The "type" parameter for multipart/related (RFC 2387)
    public static let type = RFC_2045.Parameter.Name(rawValue: "type")

    /// The "start" parameter for multipart/related (RFC 2387)
    public static let start = RFC_2045.Parameter.Name(rawValue: "start")

    /// The "start-info" parameter for multipart/related (RFC 2387)
    public static let startInfo = RFC_2045.Parameter.Name(rawValue: "start-info")
}

// MARK: - Binary.Serializable ([FAM-012] — Related is byte-domain, Binary-only; composes Multipart)

extension RFC_2387.Related: Binary.Serializable {
    /// Serializes the whole multipart/related body as wire bytes.
    ///
    /// [FAM-012] `Related` composes `RFC_2046.Multipart`, which is byte-domain (its
    /// parts may carry binary / MIME-encoded content), so `Related` conforms to
    /// `Binary.Serializable` ONLY — there is no ASCII-text sibling. Serialization is
    /// context-free — the value carries its own boundary. Clause-9: composes
    /// `RFC_2046.Multipart`'s own `Byte` verb directly into the sink — never a
    /// `[Byte]`-intermediate detour, never a sub-part `rawValue` reach-in.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ related: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        // clause-9: Multipart Byte verb
        RFC_2046.Multipart.serialize(related.multipart, into: &buffer)
    }
}

// MARK: - Computed Properties

extension RFC_2387.Related {
    /// The Content-Type header value for this multipart/related message
    public var contentType: RFC_2045.ContentType {
        multipart.contentType
    }

    /// The body parts in this multipart/related message
    public var parts: [RFC_2046.BodyPart] {
        multipart.parts
    }

    /// The boundary delimiter
    public var boundary: RFC_2046.Boundary {
        multipart.boundary
    }

    /// The root body part (first part or part matching start)
    public var rootPart: RFC_2046.BodyPart? {
        multipart.parts.first
    }
}
