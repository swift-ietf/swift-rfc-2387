import RFC_2046

extension RFC_2387.Related {

    public enum Error: Swift.Error, Sendable, Equatable {

        case emptyParts

        case missingRootType

        case startNotFound(RFC_2387.ContentID)

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
