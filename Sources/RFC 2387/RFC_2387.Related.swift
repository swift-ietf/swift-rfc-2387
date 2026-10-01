public import Byte
public import RFC_2045
public import RFC_2046
public import RFC_5322

extension RFC_2387 {

    public struct Related: Sendable, Hashable {

        public let multipart: RFC_2046.Multipart

        public let rootType: RFC_2045.ContentType

        public let start: ContentID?

        public let startInfo: String?

        package init(
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

            try Self.validate(start: start, rootPart: rootPart)

            var parameters: [RFC_2045.Parameter.Name: String] = [:]

            parameters[.type] = Self.typeParameterValue(for: rootType)
            if let start {

                parameters[.start] = start.description
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

extension RFC_2387.Related {

    package static func validate(
        start: RFC_2387.ContentID?,
        rootPart: RFC_2046.BodyPart
    ) throws(Error) {
        if let start, rootPart.contentID != start {
            throw Error.startNotFound(start)
        }
    }

    package static func inconsistency(
        multipart: RFC_2046.Multipart,
        rootType: RFC_2045.ContentType,
        start: RFC_2387.ContentID?,
        startInfo: String?
    ) -> String? {
        guard multipart.subtype == .related else {
            return "multipart subtype is \(multipart.subtype), not related"
        }
        guard let rootPart = multipart.parts.first else {
            return Error.emptyParts.description
        }
        guard rootPart.contentType == rootType else {
            return "rootType does not match the root part's Content-Type"
        }
        do throws(Error) {
            try validate(start: start, rootPart: rootPart)
        } catch {
            return error.description
        }
        guard multipart.additionalParameters[.type] == typeParameterValue(for: rootType) else {
            return "type parameter does not describe rootType"
        }
        guard multipart.additionalParameters[.start] == start?.description else {
            return "start parameter does not match start"
        }
        guard multipart.additionalParameters[.startInfo] == startInfo else {
            return "start-info parameter does not match startInfo"
        }
        return nil
    }
}

extension RFC_2046.BodyPart {

    public var contentID: RFC_2387.ContentID? {
        guard
            let header = headers.custom.first(where: { $0.name == RFC_5322.Header.Name.contentId })
        else { return nil }
        return try? RFC_2387.ContentID(header.value.rawValue)
    }
}

extension RFC_2387.Related {

    public static func inline(
        contentID: RFC_2387.ContentID,
        contentType: RFC_2045.ContentType,
        transferEncoding: RFC_2045.ContentTransferEncoding = .base64,
        content: [Byte]
    ) throws(RFC_5322.Header.Value.Error) -> RFC_2046.BodyPart {
        var headers = RFC_2046.BodyPart.Headers()
        headers.contentType = contentType
        headers.contentTransferEncoding = transferEncoding

        headers.custom.append(
            RFC_5322.Header(
                name: .contentId,
                value: try RFC_5322.Header.Value(contentID.description)
            )
        )

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

            parameters[.start] = start.description
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

    public static let type = Self(__unchecked: (), rawValue: "type")

    public static let start = Self(__unchecked: (), rawValue: "start")

    public static let startInfo = Self(__unchecked: (), rawValue: "start-info")
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
