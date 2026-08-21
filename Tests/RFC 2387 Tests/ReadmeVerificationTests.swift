import Foundation
import RFC_2045
import RFC_2046
import RFC_5322
import Testing

@testable import RFC_2387

@Suite
struct `RFC 2387 Related Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `RFC 2387 Related Tests`.Unit {

    @Test
    func `Creating multipart/related with HTML and inline image`() throws {
        let htmlPart = try RFC_2046.BodyPart(
            contentType: .textHTMLUTF8,
            text: "<img src='cid:logo@example.com'>"
        )

        let imagePart = try RFC_2387.Related.inline(
            contentID: "logo@example.com",
            contentType: .imagePNG,
            content: [.ascii.P, .ascii.N, .ascii.G]
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
    func `Using inline convenience method`() throws {
        let imagePart = try RFC_2387.Related.inline(
            contentID: "logo@example.com",
            contentType: .imagePNG,
            content: [.ascii.J, .ascii.P, .ascii.G]
        )

        #expect(imagePart.contentID == "<logo@example.com>")
        #expect(imagePart.contentType?.type == "image")
        #expect(imagePart.contentType?.subtype == "png")
    }

    @Test
    func `Related subtype constant`() {
        let related = RFC_2046.Multipart.Subtype.related

        #expect(related.rawValue == "related")
    }

    @Test
    func `ContentID accessor`() throws {
        let imagePart = try RFC_2387.Related.inline(
            contentID: "test@example.com",
            contentType: .imageGIF,
            content: []
        )

        let contentID = imagePart.contentID
        #expect(contentID == "<test@example.com>")
    }

    @Test
    func `Multipart/related with root type parameter`() throws {
        let htmlPart = try RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Test</p>")

        let imagePart = try RFC_2387.Related.inline(
            contentID: "img@example.com",
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
        let htmlPart = try RFC_2046.BodyPart(
            contentType: .textHTMLUTF8,
            text: "<html><body>Test</body></html>"
        )

        let boundary = try RFC_2046.Boundary("----=_Part_\(UUID().uuidString)")
        let related = try RFC_2387.Related.multipart(
            rootPart: htmlPart,
            relatedParts: [],
            boundary: boundary,
            start: "root@example.com"
        )

        #expect(related.subtype == .related)
        #expect(related.parts.count == 1)
    }

    @Test
    func `Multipart/related with custom boundary`() throws {
        let htmlPart = try RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Content</p>")

        let customBoundary = try RFC_2046.Boundary("CustomBoundary123")
        let related = try RFC_2387.Related.multipart(
            rootPart: htmlPart,
            relatedParts: [],
            boundary: customBoundary
        )

        #expect(String(related.boundary) == "CustomBoundary123")
    }

    @Test
    func `Multiple inline images in multipart/related`() throws {
        let htmlContent = """
            <html>
                <img src="cid:logo@example.com">
                <img src="cid:banner@example.com">
            </html>
            """
        let htmlPart = try RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: htmlContent)

        let logoPart = try RFC_2387.Related.inline(
            contentID: "logo@example.com",
            contentType: .imagePNG,
            content: [.ascii.l, .ascii.o, .ascii.g, .ascii.o]
        )

        let bannerPart = try RFC_2387.Related.inline(
            contentID: "banner@example.com",
            contentType: .imageJPEG,
            content: [.ascii.b, .ascii.a, .ascii.n, .ascii.n, .ascii.e, .ascii.r]
        )

        let boundary = try RFC_2046.Boundary("----=_Part_\(UUID().uuidString)")
        let related = try RFC_2387.Related.multipart(
            rootPart: htmlPart,
            relatedParts: [logoPart, bannerPart],
            boundary: boundary
        )

        #expect(related.parts.count == 3)
        #expect(related.parts[1].contentID == "<logo@example.com>")
        #expect(related.parts[2].contentID == "<banner@example.com>")
    }

    @Test
    func `RFC_2387 namespace exists`() {

        _ = RFC_2387.self
    }

    @Test
    func `RFC_2387.Related type exists`() {

        _ = RFC_2387.Related.self
    }

    @Test
    func `Creating Related struct directly`() throws {
        let htmlPart = try RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Test</p>")

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

    @Test
    func `Related struct serialization round-trip`() throws {
        let htmlPart = try RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Hello</p>")

        let boundary = try RFC_2046.Boundary("----=_Test_Boundary")
        let related = try RFC_2387.Related(
            rootPart: htmlPart,
            relatedParts: [],
            boundary: boundary
        )

        let bytes = [UInt8](related)

        let serialized = String(decoding: bytes, as: UTF8.self)
        #expect(serialized.contains("----=_Test_Boundary"))
    }

    @Test
    func `ContentID type is RFC_5322.Message.ID`() throws {

        let contentID: RFC_2387.ContentID = "test@example.com"

        let serialized = String(contentID)
        #expect(serialized == "<test@example.com>")
    }
}
