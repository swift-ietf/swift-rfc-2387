#if Coder
import Byte
import Byte
import RFC_2045
import RFC_2046
import RFC_2046_Coder
import RFC_2387
import RFC_2387_Coder
import RFC_5322
import Testing

@Suite
struct `Related - Coder round trip` {
    @Test
    func `Coder round-trips an HTML root with an inline image`() throws {
        let htmlPart = RFC_2046.BodyPart(
            contentType: .textHTMLUTF8,
            text: "<img src='cid:logo@example.com'>"
        )
        let imagePart = try RFC_2387.Related.inline(
            contentID: try RFC_2387.ContentID("logo@example.com"),
            contentType: .imagePNG,
            content: [Byte](utf8: "PNG")
        )
        let boundary = try RFC_2046.Boundary("----=_Part_2387")
        let original = try RFC_2387.Related(
            rootPart: htmlPart,
            relatedParts: [imagePart],
            boundary: boundary
        )

        let coder = RFC_2387.Related.coder(boundary: boundary)

        var wire: [Byte] = []
        try coder.serialize(original, into: &wire)

        var input = wire[...]
        let parsed = try coder.parse(&input)

        #expect(input.isEmpty)
        #expect(parsed.boundary == boundary)
        #expect(parsed.parts.count == 2)
        #expect(parsed.rootType.type == "text")
        #expect(parsed.rootType.subtype == "html")
        #expect(parsed.parts[0].content.rawValue == [Byte](utf8: "<img src='cid:logo@example.com'>"))
        #expect(parsed.parts[1].contentID == (try RFC_2387.ContentID("logo@example.com")))
        #expect(parsed.parts[1].content.rawValue == [Byte](utf8: "PNG"))
        #expect(parsed.parts[1].contentType?.subtype == "png")
    }

    @Test
    func `Serialized body is delimited by the boundary`() throws {
        let htmlPart = RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Hello</p>")
        let boundary = try RFC_2046.Boundary("rel-boundary")
        let related = try RFC_2387.Related(
            rootPart: htmlPart,
            relatedParts: [],
            boundary: boundary
        )

        let text = String(decoding: [Byte](related), as: UTF8.self)

        #expect(text.hasPrefix("--rel-boundary\r\n"))
        #expect(text.hasSuffix("--rel-boundary--\r\n"))
        #expect(text.contains("<p>Hello</p>"))
    }

    @Test
    func `Related serializes exactly as its multipart`() throws {
        let htmlPart = RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Hello</p>")
        let boundary = try RFC_2046.Boundary("rel-boundary")
        let related = try RFC_2387.Related(
            rootPart: htmlPart,
            relatedParts: [],
            boundary: boundary
        )

        #expect([Byte](related) == [Byte](related.multipart))
    }
}

@Suite
struct `Related - Coder rejections` {
    @Test
    func `Coder rejects a body whose root part has no Content-Type`() throws {
        let raw = "--b\r\n\r\nhello\r\n--b--\r\n"
        let boundary = try RFC_2046.Boundary("b")
        let coder = RFC_2387.Related.coder(boundary: boundary)

        var input = [Byte](utf8: raw)[...]
        #expect(throws: RFC_2387.Related.Error.missingRootType) {
            _ = try coder.parse(&input)
        }
        #expect(input.count == raw.utf8.count)
    }

    @Test
    func `Coder rejects a body delimited by a different boundary`() throws {
        let raw = "--other\r\nContent-Type: text/html\r\n\r\nhello\r\n--other--\r\n"
        let boundary = try RFC_2046.Boundary("b")
        let coder = RFC_2387.Related.coder(boundary: boundary)

        var input = [Byte](utf8: raw)[...]
        #expect(throws: RFC_2387.Related.Error.multipartError(.emptyParts)) {
            _ = try coder.parse(&input)
        }
    }
}
#endif
