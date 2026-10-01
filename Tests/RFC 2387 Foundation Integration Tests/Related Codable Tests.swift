import Byte
import Foundation
import RFC_2045
import RFC_2046
import RFC_2387
import RFC_2387_Foundation_Integration
import RFC_5322
import Testing

@Suite
struct `Related - Codable` {

    struct Shape: Decodable {

        struct RootType: Decodable {
            let type: String
            let subtype: String
        }

        let rootType: RootType
        let start: String?
        let startInfo: String?
    }

    static func root(id: String) throws -> RFC_2046.BodyPart {
        try RFC_2387.Related.inline(
            contentID: try RFC_2387.ContentID(id),
            contentType: .textHTMLUTF8,
            content: [Byte](utf8: "<p>Hello</p>")
        )
    }

    static func encodedObject(
        _ mutate: (inout [String: Any]) -> Void
    ) throws -> Data {
        let related = try RFC_2387.Related(
            rootPart: try root(id: "root@example.com"),
            relatedParts: [
                try RFC_2387.Related.inline(
                    contentID: try RFC_2387.ContentID("logo@example.com"),
                    contentType: .imagePNG,
                    content: [Byte](utf8: "PNG")
                )
            ],
            boundary: try RFC_2046.Boundary("----=_Test_Boundary"),
            start: try RFC_2387.ContentID("root@example.com"),
            startInfo: "-o ps"
        )
        var object = try #require(
            try JSONSerialization.jsonObject(with: try JSONEncoder().encode(related)) as? [String: Any]
        )
        mutate(&object)
        return try JSONSerialization.data(withJSONObject: object)
    }

    @Test
    func `Decoding the unmodified encoding of a rooted value succeeds`() throws {
        let decoded = try JSONDecoder().decode(RFC_2387.Related.self, from: try Self.encodedObject { _ in })
        #expect(decoded.start == (try RFC_2387.ContentID("root@example.com")))
        #expect(decoded.parts.count == 2)
    }

    @Test
    func `Decoding a non-related multipart subtype throws`() throws {
        let data = try Self.encodedObject { object in
            var multipart = object["multipart"] as! [String: Any]
            multipart["subtype"] = "mixed"
            object["multipart"] = multipart
        }
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_2387.Related.self, from: data)
        }
    }

    @Test
    func `Decoding a root type that contradicts the root part throws`() throws {
        let data = try Self.encodedObject { object in
            var rootType = object["rootType"] as! [String: Any]
            rootType["subtype"] = "plain"
            object["rootType"] = rootType
        }
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_2387.Related.self, from: data)
        }
    }

    @Test
    func `Decoding a start that names only a related part throws`() throws {
        let data = try Self.encodedObject { object in
            object["start"] = "<logo@example.com>"
        }
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_2387.Related.self, from: data)
        }
    }

    @Test
    func `Decoding without start while the start parameter remains throws`() throws {
        let data = try Self.encodedObject { object in
            object["start"] = nil
        }
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_2387.Related.self, from: data)
        }
    }

    @Test
    func `Decoding a start-info that contradicts the parameter throws`() throws {
        let data = try Self.encodedObject { object in
            object["startInfo"] = "-o other"
        }
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_2387.Related.self, from: data)
        }
    }

    @Test
    func `Round-trip preserves start and start-info`() throws {
        let original = try RFC_2387.Related(
            rootPart: try Self.root(id: "root@example.com"),
            relatedParts: [],
            boundary: try RFC_2046.Boundary("----=_Test_Boundary"),
            start: try RFC_2387.ContentID("root@example.com"),
            startInfo: "-o ps"
        )

        let decoded = try JSONDecoder().decode(
            RFC_2387.Related.self,
            from: try JSONEncoder().encode(original)
        )

        #expect(decoded == original)
        #expect(decoded.start == (try RFC_2387.ContentID("root@example.com")))
        #expect(decoded.startInfo == "-o ps")
        #expect(decoded.boundary == original.boundary)
    }

    @Test
    func `Round-trip without start keeps optionals absent`() throws {
        let original = try RFC_2387.Related(
            rootPart: RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Hello</p>"),
            relatedParts: [],
            boundary: try RFC_2046.Boundary("----=_Test_Boundary")
        )

        let decoded = try JSONDecoder().decode(
            RFC_2387.Related.self,
            from: try JSONEncoder().encode(original)
        )

        #expect(decoded == original)
        #expect(decoded.start == nil)
        #expect(decoded.startInfo == nil)
    }

    @Test
    func `Round-trip preserves inline related parts`() throws {
        let original = try RFC_2387.Related(
            rootPart: RFC_2046.BodyPart(
                contentType: .textHTMLUTF8,
                text: "<img src='cid:logo@example.com'>"
            ),
            relatedParts: [
                try RFC_2387.Related.inline(
                    contentID: try RFC_2387.ContentID("logo@example.com"),
                    contentType: .imagePNG,
                    content: [Byte](utf8: "PNG")
                )
            ],
            boundary: try RFC_2046.Boundary("----=_Test_Boundary")
        )

        let decoded = try JSONDecoder().decode(
            RFC_2387.Related.self,
            from: try JSONEncoder().encode(original)
        )

        #expect(decoded == original)
        #expect(decoded.parts.count == 2)
        #expect(decoded.parts[1].contentID == (try RFC_2387.ContentID("logo@example.com")))
        #expect(decoded.multipart.subtype == .related)
    }

    @Test
    func `Encoding writes root type, start and start-info fields`() throws {
        let related = try RFC_2387.Related(
            rootPart: try Self.root(id: "root@example.com"),
            relatedParts: [],
            boundary: try RFC_2046.Boundary("----=_Test_Boundary"),
            start: try RFC_2387.ContentID("root@example.com"),
            startInfo: "-o ps"
        )

        let shape = try JSONDecoder().decode(Shape.self, from: try JSONEncoder().encode(related))

        #expect(shape.rootType.type == "text")
        #expect(shape.rootType.subtype == "html")
        #expect(shape.start == "<root@example.com>")
        #expect(shape.startInfo == "-o ps")
    }

    @Test
    func `Encoding omits absent start and start-info`() throws {
        let related = try RFC_2387.Related(
            rootPart: RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Hello</p>"),
            relatedParts: [],
            boundary: try RFC_2046.Boundary("----=_Test_Boundary")
        )

        let shape = try JSONDecoder().decode(Shape.self, from: try JSONEncoder().encode(related))

        #expect(shape.start == nil)
        #expect(shape.startInfo == nil)
    }

    @Test
    func `Decoding a start without an at sign throws`() throws {
        let related = try RFC_2387.Related(
            rootPart: try Self.root(id: "root@example.com"),
            relatedParts: [],
            boundary: try RFC_2046.Boundary("----=_Test_Boundary"),
            start: try RFC_2387.ContentID("root@example.com")
        )
        let json = String(decoding: try JSONEncoder().encode(related), as: UTF8.self)
        let corrupted = json.replacingOccurrences(of: "<root@example.com>", with: "root-example")

        #expect(corrupted != json)
        #expect(throws: RFC_5322.Message.ID.Error.missingAtSign("root-example")) {
            try JSONDecoder().decode(RFC_2387.Related.self, from: Data(corrupted.utf8))
        }
    }

    @Test
    func `Decoding without a root type throws`() throws {
        let related = try RFC_2387.Related(
            rootPart: RFC_2046.BodyPart(contentType: .textHTMLUTF8, text: "<p>Hello</p>"),
            relatedParts: [],
            boundary: try RFC_2046.Boundary("----=_Test_Boundary")
        )
        let json = String(decoding: try JSONEncoder().encode(related), as: UTF8.self)
        let corrupted = json.replacingOccurrences(of: "\"rootType\"", with: "\"rootKind\"")

        #expect(corrupted != json)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_2387.Related.self, from: Data(corrupted.utf8))
        }
    }

    @Test
    func `Decoding an empty object throws`() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_2387.Related.self, from: Data("{}".utf8))
        }
    }
}
