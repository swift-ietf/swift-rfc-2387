#if Coder
public import Binary
public import Byte
public import RFC_2387
import RFC_2046
import RFC_2046_Coder

extension RFC_2387.Related: @retroactive Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ related: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        RFC_2046.Multipart.serialize(related.multipart, into: &buffer)
    }
}

extension [Byte] {

    public init(_ related: RFC_2387.Related) {
        self = []
        RFC_2387.Related.serialize(related, into: &self)
    }
}
#endif
