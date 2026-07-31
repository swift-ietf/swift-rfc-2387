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

import RFC_2046

extension RFC_2387.Related {
    /// Errors that occur during RFC 2387 multipart/related parsing or validation
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The multipart message has no body parts
        case emptyParts

        /// The root part is missing a Content-Type header
        case missingRootType

        /// The specified start Content-ID was not found in any part
        case startNotFound(RFC_2387.ContentID)

        /// An error occurred parsing the underlying multipart message
        case multipartError(RFC_2046.Multipart.Error)
    }
}

extension RFC_2387.Related.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyParts:
            return "Multipart/related must have at least one body part"

        case .missingRootType:
            return "Root part must have a Content-Type header"

        case .startNotFound(let id):
            return "Start Content-ID '\(id)' not found in any body part"

        case .multipartError(let error):
            return "Multipart error: \(error)"
        }
    }
}
