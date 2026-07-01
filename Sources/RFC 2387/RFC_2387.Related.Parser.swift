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

// RFC_2387.Related.Parser.swift
// swift-rfc-2387

public import Parser_Primitives
public import Byte_Parser_Primitives
public import RFC_2046

extension RFC_2387.Related {
    /// Parser witness carrying the out-of-band parse CONTEXT a multipart/related
    /// body needs — the boundary delimiter — as a stored VALUE.
    ///
    /// ## [FAM-012] §11 — context as a parser-witness VALUE
    ///
    /// multipart/related parsing is context-dependent: the same raw bytes decode to
    /// different structures depending on the boundary delimiter. Per the
    /// serialize/parse codec-attachment model §11, that context is **NOT** an
    /// `associatedtype Context` on a flat parse marker ([FAM-001]). It is carried by a
    /// **witness VALUE the caller constructs with the context and passes in** (the
    /// serde `DeserializeSeed` shape). The caller able to supply the boundary is
    /// concrete by construction, so the realistic site is:
    ///
    /// ```swift
    /// let related = try RFC_2387.Related.parse(
    ///     from: bytes,
    ///     parser: RFC_2387.Related.Parser(boundary: boundary)
    /// )
    /// ```
    ///
    /// The witness conforms to the ecosystem `Parser.`Protocol`` — symmetric with the
    /// serializer variant-witnesses conforming to `Serializer.`Protocol`` — so the
    /// context lives on the witness value while the flat parse marker stays
    /// context-free ([FAM-001]).
    ///
    /// Clause-9: this witness composes `RFC_2046.Multipart.Parser` directly on the
    /// same byte cursor (subtype fixed to `.related`) — never a `[Byte]`-detour — then
    /// lifts the parsed `Multipart` into RFC 2387 semantics (root = first part).
    ///
    /// The parse is intentionally **boundary-only**, faithfully preserving the
    /// pre-drain `init(ascii:in:)` behavior: the `start` / `start-info` parameters are
    /// NOT threaded as parse inputs (`start` / `startInfo` are derived as `nil`,
    /// `rootType` from the first part). This mirrors the retired `Context`, which
    /// stored the boundary alone.
    public struct Parser: Parser_Primitives.Parser.`Protocol`, Sendable {
        public typealias Input = Byte.Input
        public typealias Output = RFC_2387.Related
        public typealias Failure = RFC_2387.Related.Error
        public typealias Body = Never

        /// The boundary delimiter separating body parts.
        public let boundary: RFC_2046.Boundary

        /// Builds the parser witness with its parse context.
        ///
        /// - Parameter boundary: The boundary delimiter for the multipart/related message.
        public init(boundary: RFC_2046.Boundary) {
            self.boundary = boundary
        }

        /// Parses a multipart/related body from the byte cursor `input`, consuming it.
        ///
        /// [FAM-012] `Parser.`Protocol`` cursor-form leaf parser: composes
        /// `RFC_2046.Multipart.Parser` (subtype `.related`) on the same cursor
        /// (clause-9), then lifts the `Multipart` into `Related`.
        ///
        /// - Parameter input: The byte cursor to consume.
        /// - Returns: The parsed multipart/related value.
        /// - Throws: `RFC_2387.Related.Error` if parsing fails.
        public borrowing func parse(
            _ input: inout Byte.Input
        ) throws(RFC_2387.Related.Error) -> RFC_2387.Related {
            // Clause-9: compose RFC_2046.Multipart's own Byte-cursor parse verb.
            let multipart: RFC_2046.Multipart
            do {
                multipart = try RFC_2046.Multipart.Parser(
                    boundary: boundary,
                    subtype: .related
                ).parse(&input)
            } catch {
                throw RFC_2387.Related.Error.multipartError(error)
            }

            // RFC 2387: the root is the first part.
            guard let firstPart = multipart.parts.first else {
                throw RFC_2387.Related.Error.emptyParts
            }
            guard let rootType = firstPart.contentType else {
                throw RFC_2387.Related.Error.missingRootType
            }

            return RFC_2387.Related(
                __unchecked: (),
                multipart: multipart,
                rootType: rootType,
                start: nil,
                startInfo: nil
            )
        }
    }

    /// Parses a multipart/related body from `bytes`, with the parse CONTEXT carried by
    /// the `parser` witness VALUE ([FAM-012] §11 — the ergonomic context-bearing entry).
    ///
    /// Builds the canonical `Byte.Input` cursor from `bytes` and delegates to the
    /// witness's `Parser.`Protocol`` cursor `parse(_:)`.
    ///
    /// - Parameters:
    ///   - bytes: The multipart/related message body as wire bytes.
    ///   - parser: The parser witness carrying the boundary.
    /// - Throws: `RFC_2387.Related.Error` if parsing fails.
    public static func parse<Bytes: Swift.Collection>(
        from bytes: Bytes,
        parser: Parser
    ) throws(Error) -> RFC_2387.Related
    where Bytes.Element == Byte {
        var input = Byte.Input(bytes)
        return try parser.parse(&input)
    }
}
