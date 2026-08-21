import ASCII_Serializer_Primitives
public import RFC_2045
public import RFC_2046
public import RFC_5322

extension RFC_2387 {

    public struct Related: Sendable, Hashable, Codable {

        public let multipart: RFC_2046.Multipart

        public let rootType: RFC_2045.ContentType

        public let start: ContentID?

        public let startInfo: String?

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

        public init(
            rootPart: RFC_2046.BodyPart,
            relatedParts: [RFC_2046.BodyPart],
            boundary: RFC_2046.Boundary,
            start: ContentID? = nil,
            startInfo: String? = nil
        ) throws(Error) {
            let allParts = [rootPart] + relatedParts

            guard let rootType = rootPart.contentType else {
                throw Error.missingRootType
            }

            var parameters: [RFC_2045.Parameter.Name: String] = [:]

            parameters[.type] = Self.typeParameterValue(for: rootType)
            if let start {

                parameters[.start] = String(start)
            }
            if let startInfo {
                parameters[.startInfo] = startInfo
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

extension RFC_2387.Related {

    static func typeParameterValue(for contentType: RFC_2045.ContentType) -> String {
        "\(contentType.type)/\(contentType.subtype)"
    }
}

extension RFC_2046.BodyPart {

    public var contentID: String? {
        headers[.contentId]
    }
}

extension RFC_2387.Related {

    public static func inline(
        contentID: RFC_2387.ContentID,
        contentType: RFC_2045.ContentType,
        transferEncoding: RFC_2045.ContentTransferEncoding = .base64,
        content: [Byte]
    ) -> RFC_2046.BodyPart {
        var headers = RFC_2046.BodyPart.Headers()
        headers.contentType = contentType
        headers.contentTransferEncoding = transferEncoding

        headers[.contentId] = String(contentID)

        return RFC_2046.BodyPart(
            headers: headers,
            content: RFC_2046.BodyPart.Content(content)
        )
    }

    public static func multipart(
        rootPart: RFC_2046.BodyPart,
        relatedParts: [RFC_2046.BodyPart],
        boundary: RFC_2046.Boundary,
        rootType: RFC_2045.ContentType? = nil,
        start: RFC_2387.ContentID? = nil
    ) throws(RFC_2046.Multipart.Error) -> RFC_2046.Multipart {
        let allParts = [rootPart] + relatedParts

        let detectedRootType = rootType ?? rootPart.contentType

        var parameters: [RFC_2045.Parameter.Name: String] = [:]
        if let type = detectedRootType {

            parameters[.type] = RFC_2387.Related.typeParameterValue(for: type)
        }
        if let start {

            parameters[.start] = String(start)
        }

        return try RFC_2046.Multipart(
            subtype: .related,
            parts: allParts,
            boundary: boundary,
            additionalParameters: parameters
        )
    }
}

extension RFC_2045.Parameter.Name {

    public static let type = RFC_2045.Parameter.Name(rawValue: "type")

    public static let start = RFC_2045.Parameter.Name(rawValue: "start")

    public static let startInfo = RFC_2045.Parameter.Name(rawValue: "start-info")
}

extension RFC_2387.Related: Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ related: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {

        RFC_2046.Multipart.serialize(related.multipart, into: &buffer)
    }
}

extension RFC_2387.Related {

    public var contentType: RFC_2045.ContentType {
        multipart.contentType
    }

    public var parts: [RFC_2046.BodyPart] {
        multipart.parts
    }

    public var boundary: RFC_2046.Boundary {
        multipart.boundary
    }

    public var rootPart: RFC_2046.BodyPart? {
        multipart.parts.first
    }
}
