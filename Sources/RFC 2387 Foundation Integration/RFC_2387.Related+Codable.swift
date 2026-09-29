import RFC_2045
import RFC_2045_Foundation_Integration
import RFC_2046
import RFC_2046_Foundation_Integration
public import RFC_2387
import RFC_5322
import RFC_5322_Foundation_Integration

extension RFC_2387.Related: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {
        case multipart
        case rootType
        case start
        case startInfo
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            __unchecked: (),
            multipart: try container.decode(RFC_2046.Multipart.self, forKey: .multipart),
            rootType: try container.decode(RFC_2045.ContentType.self, forKey: .rootType),
            start: try container.decodeIfPresent(RFC_2387.ContentID.self, forKey: .start),
            startInfo: try container.decodeIfPresent(String.self, forKey: .startInfo)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(multipart, forKey: .multipart)
        try container.encode(rootType, forKey: .rootType)
        try container.encodeIfPresent(start, forKey: .start)
        try container.encodeIfPresent(startInfo, forKey: .startInfo)
    }
}
