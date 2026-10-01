import Byte
import Foundation
import RFC_2045
import RFC_2046
import RFC_2387
import RFC_5322
import Testing

@Suite
struct `Related - Building multipart/related` {

    @Test
    func `Creating multipart/related with HTML and inline image`() throws {
        let htmlPart = RFC_2046.BodyPart(
            contentType: .textHTMLUTF8,
            text: "<img src='cid:logo@example.com'>"
        )

        let imagePart = try RFC_2387.Related.inline(
            contentID: try RFC_2387.ContentID("logo@example.com"),
            contentType: .imagePNG,
            content: [Byte](utf8: "PNG")
        )

        let boundary = try RFC_2046.Boundary("----=_Part_\(UUID().uuidString)")
        let related = try RFC_2387.Related.multipart(
            rootPart: htmlPart,
            relatedParts: [imagePart],
            boundary: boundary
        )

        #expect(related.subtype == .related)
        #expect(related.parts.count == 2)
    }

    @Test
    func `Multipart/related with root type parameter`() throws {
        let htmlPart = RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Test</p>")

        let imagePart = try RFC_2387.Related.inline(
            contentID: try RFC_2387.ContentID("img@example.com"),
            contentType: .imageJPEG,
            content: []
        )

        let boundary = try RFC_2046.Boundary("----=_Part_\(UUID().uuidString)")
        let related = try RFC_2387.Related.multipart(
            rootPart: htmlPart,
            relatedParts: [imagePart],
            boundary: boundary,
            rootType: .textHTMLUTF8
        )

        #expect(related.subtype == .related)
        #expect(related.parts.count == 2)
    }

    @Test
    func `Multipart/related with start Content-ID parameter`() throws {
        let htmlPart = RFC_2046.BodyPart(
            contentType: .textHTMLUTF8,
            text: "<html><body>Test</body></html>"
        )

        let boundary = try RFC_2046.Boundary("----=_Part_\(UUID().uuidString)")
        let related = try RFC_2387.Related.multipart(
            rootPart: htmlPart,
            relatedParts: [],
            boundary: boundary,
            start: try RFC_2387.ContentID("root@example.com")
        )

        #expect(related.subtype == .related)
        #expect(related.parts.count == 1)
    }

    @Test
    func `Multipart/related with custom boundary`() throws {
        let htmlPart = RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Content</p>")

        let customBoundary = try RFC_2046.Boundary("CustomBoundary123")
        let related = try RFC_2387.Related.multipart(
            rootPart: htmlPart,
            relatedParts: [],
            boundary: customBoundary
        )

        #expect(related.boundary == customBoundary)
    }

    @Test
    func `Multiple inline images in multipart/related`() throws {
        let htmlContent = """
            <html>
                <img src="cid:logo@example.com">
                <img src="cid:banner@example.com">
            </html>
            """
        let htmlPart = RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: htmlContent)

        let logoPart = try RFC_2387.Related.inline(
            contentID: try RFC_2387.ContentID("logo@example.com"),
            contentType: .imagePNG,
            content: [Byte](utf8: "logo")
        )

        let bannerPart = try RFC_2387.Related.inline(
            contentID: try RFC_2387.ContentID("banner@example.com"),
            contentType: .imageJPEG,
            content: [Byte](utf8: "banner")
        )

        let boundary = try RFC_2046.Boundary("----=_Part_\(UUID().uuidString)")
        let related = try RFC_2387.Related.multipart(
            rootPart: htmlPart,
            relatedParts: [logoPart, bannerPart],
            boundary: boundary
        )

        #expect(related.parts.count == 3)
        #expect(related.parts[1].contentID == (try RFC_2387.ContentID("logo@example.com")))
        #expect(related.parts[2].contentID == (try RFC_2387.ContentID("banner@example.com")))
    }

    @Test
    func `Creating Related struct directly`() throws {
        let htmlPart = RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Test</p>")

        let boundary = try RFC_2046.Boundary("----=_Part_\(UUID().uuidString)")
        let related = try RFC_2387.Related(
            rootPart: htmlPart,
            relatedParts: [],
            boundary: boundary
        )

        #expect(related.rootType.type == "text")
        #expect(related.rootType.subtype == "html")
        #expect(related.parts.count == 1)
    }
}

@Suite
struct `Related - Content-ID` {

    @Test
    func `Using inline convenience method`() throws {
        let imagePart = try RFC_2387.Related.inline(
            contentID: try RFC_2387.ContentID("logo@example.com"),
            contentType: .imagePNG,
            content: [Byte](utf8: "JPG")
        )

        #expect(imagePart.contentID == (try RFC_2387.ContentID("logo@example.com")))
        #expect(imagePart.contentType?.type == "image")
        #expect(imagePart.contentType?.subtype == "png")
    }

    @Test
    func `Content-ID accessor returns the typed Content-ID`() throws {
        let imagePart = try RFC_2387.Related.inline(
            contentID: try RFC_2387.ContentID("test@example.com"),
            contentType: .imageGIF,
            content: []
        )

        #expect(imagePart.contentID == (try RFC_2387.ContentID("test@example.com")))
    }

    @Test
    func `Content-ID is the RFC 5322 message identifier`() throws {
        let contentID = try RFC_2387.ContentID("test@example.com")

        #expect(contentID.description == "<test@example.com>")
    }
}

@Suite
struct `Related - start names the root part` {

    static func root(id: String?) throws -> RFC_2046.BodyPart {
        guard let id else {
            return RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Root</p>")
        }
        return try RFC_2387.Related.inline(
            contentID: try RFC_2387.ContentID(id),
            contentType: .textHTMLUTF8,
            content: [Byte](utf8: "<p>Root</p>")
        )
    }

    static func image(id: String) throws -> RFC_2046.BodyPart {
        try RFC_2387.Related.inline(
            contentID: try RFC_2387.ContentID(id),
            contentType: .imagePNG,
            content: [Byte](utf8: "PNG")
        )
    }

    @Test
    func `start equal to the root Content-ID is accepted`() throws {
        let related = try RFC_2387.Related(
            rootPart: try Self.root(id: "root@example.com"),
            relatedParts: [try Self.image(id: "logo@example.com")],
            boundary: try RFC_2046.Boundary("b"),
            start: try RFC_2387.ContentID("root@example.com")
        )
        #expect(related.start == (try RFC_2387.ContentID("root@example.com")))
        #expect(related.rootPart?.contentID == related.start)
    }

    @Test
    func `absent start accepts a root without a Content-ID`() throws {
        let related = try RFC_2387.Related(
            rootPart: try Self.root(id: nil),
            relatedParts: [try Self.image(id: "logo@example.com")],
            boundary: try RFC_2046.Boundary("b")
        )
        #expect(related.start == nil)
        #expect(related.parts.count == 2)
    }

    @Test
    func `start with a root that has no Content-ID is refused`() throws {
        let start = try RFC_2387.ContentID("root@example.com")
        #expect(throws: RFC_2387.Related.Error.startNotFound(start)) {
            try RFC_2387.Related(
                rootPart: try Self.root(id: nil),
                relatedParts: [],
                boundary: try RFC_2046.Boundary("b"),
                start: start
            )
        }
    }

    @Test
    func `start different from the root Content-ID is refused`() throws {
        let start = try RFC_2387.ContentID("other@example.com")
        #expect(throws: RFC_2387.Related.Error.startNotFound(start)) {
            try RFC_2387.Related(
                rootPart: try Self.root(id: "root@example.com"),
                relatedParts: [],
                boundary: try RFC_2046.Boundary("b"),
                start: start
            )
        }
    }

    @Test
    func `start naming only a related part is refused`() throws {
        let start = try RFC_2387.ContentID("logo@example.com")
        #expect(throws: RFC_2387.Related.Error.startNotFound(start)) {
            try RFC_2387.Related(
                rootPart: try Self.root(id: "root@example.com"),
                relatedParts: [try Self.image(id: "logo@example.com")],
                boundary: try RFC_2046.Boundary("b"),
                start: start
            )
        }
    }
}
