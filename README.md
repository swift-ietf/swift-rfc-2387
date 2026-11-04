# swift-rfc-2387

Use this package when you build or read a `multipart/related` body, such as an HTML email whose images are attached and referenced by Content-ID. Start from `RFC_2387.Related`, and make each attached part with `RFC_2387.Related.inline(contentID:contentType:transferEncoding:content:)`. For other multipart subtypes, use `RFC_2046.Multipart` from swift-rfc-2046 directly.

## Laws

- The first part is always the root. The root must have a Content-Type, and every other part is a related part.
- `start` may only name the root. A `start` that doesn't equal the root's Content-ID is refused, even when it names another part. Without `start`, the root needs no Content-ID.
- The `type` parameter is the root's type and subtype only, without its parameters. `start` is written as the Content-ID in angle brackets, and `start-info` as given.
- A `RFC_2387.Related` serializes exactly as its `multipart`.
- The coder reads only the body, so a parsed value has the root's Content-Type as `rootType` and no `start` or `startInfo`. It refuses a body whose root has no Content-Type and leaves the input where it was.
- With `RFC 2387 Foundation Integration`, a value encodes as an object with `multipart`, `rootType`, `start` and `startInfo`, leaving out the last two when absent. Decoding refuses an object whose parts don't agree: a subtype other than related, no parts, a `rootType` that differs from the root's Content-Type, a `start` that isn't the root, or `type`, `start` and `start-info` parameters that don't match the fields.
