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

/// Re-export dependencies for downstream convenience
///
/// Following the standard pattern, RFC 2387 re-exports its dependencies
/// so that consumers get access to MIME types without additional imports.

@_exported public import ASCII_Serializer_Primitives
@_exported public import RFC_2045
@_exported public import RFC_2046
@_exported public import RFC_5322
