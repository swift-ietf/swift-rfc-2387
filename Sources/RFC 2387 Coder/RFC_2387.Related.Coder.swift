#if Coder
public import Byte
public import Coder
public import Cursor
public import RFC_2046
public import RFC_2387
import Binary
import Parser
import RFC_2046_Coder
import Serializer

extension RFC_2387.Related {

    public struct Coder<
        Input: Cursor.`Protocol`<Byte, Never>,
        Buffer: RangeReplaceableCollection<Byte>
    >: Coding {

        public typealias Output = RFC_2387.Related

        public typealias Failure = RFC_2387.Related.Error

        public let boundary: RFC_2046.Boundary

        public init(boundary: RFC_2046.Boundary) {
            self.boundary = boundary
        }

        public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            let start = input.checkpoint
            let multipartCoder = RFC_2046.Multipart.Coder<Input, Buffer>(
                boundary: boundary,
                subtype: .related
            )

            let multipart: RFC_2046.Multipart
            do throws(RFC_2046.Multipart.Error) {
                multipart = try multipartCoder.parse(&input)
            } catch {
                throw Failure.multipartError(error)
            }

            guard let rootPart = multipart.parts.first else {
                input.seek(to: start)
                throw Failure.emptyParts
            }

            do throws(Failure) {
                return try RFC_2387.Related(
                    rootPart: rootPart,
                    relatedParts: Array(multipart.parts.dropFirst()),
                    boundary: multipart.boundary
                )
            } catch {
                input.seek(to: start)
                throw error
            }
        }

        public borrowing func serialize(
            _ output: Output,
            into buffer: inout Buffer
        ) throws(Failure) {
            RFC_2046.Multipart.serialize(output.multipart, into: &buffer)
        }
    }

    public static func coder(
        boundary: RFC_2046.Boundary
    ) -> Coder<ArraySlice<Byte>, [Byte]> {
        .init(boundary: boundary)
    }
}
#endif
