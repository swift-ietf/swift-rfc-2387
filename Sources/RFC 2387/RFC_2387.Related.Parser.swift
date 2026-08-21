public import Byte_Parser_Primitives
public import Parser_Primitives
public import RFC_2046

extension RFC_2387.Related {

    public struct Parser: Parser_Primitives.Parser.`Protocol`, Sendable {

        public let boundary: RFC_2046.Boundary

        public init(boundary: RFC_2046.Boundary) {
            self.boundary = boundary
        }
    }
}

extension RFC_2387.Related.Parser {
    public typealias Input = Byte.Input
    public typealias Output = RFC_2387.Related
    public typealias Failure = RFC_2387.Related.Error
    public typealias Body = Never

    public borrowing func parse(
        _ input: inout Byte.Input
    ) throws(RFC_2387.Related.Error) -> RFC_2387.Related {

        let multipart: RFC_2046.Multipart
        do throws(RFC_2046.Multipart.Error) {
            multipart = try RFC_2046.Multipart.Parser(
                boundary: boundary,
                subtype: .related
            ).parse(&input)
        } catch {
            throw RFC_2387.Related.Error.multipartError(error)
        }

        guard let firstPart = multipart.parts.first else {
            throw RFC_2387.Related.Error.emptyParts
        }
        guard let rootType = firstPart.contentType else {
            throw RFC_2387.Related.Error.missingRootType
        }

        return RFC_2387.Related(
            __unchecked: (),
            multipart: multipart,
            rootType: rootType,
            start: nil,
            startInfo: nil
        )
    }
}

extension RFC_2387.Related {

    public static func parse<Bytes: Swift.Collection>(
        from bytes: Bytes,
        parser: Parser
    ) throws(Error) -> RFC_2387.Related
    where Bytes.Element == Byte {
        var input = Byte.Input(bytes)
        return try parser.parse(&input)
    }
}
