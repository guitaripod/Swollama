import Foundation

/// A type-erased JSON value.
///
/// Represents any valid JSON value — string, number, boolean, null, array, or object — while
/// remaining `Codable` and `Sendable`. Used for API fields whose shape is dynamic or open-ended,
/// such as the ``ModelInformation/modelInfo`` architecture metadata, arbitrary structured-output
/// schemas (see ``ResponseFormat/schema(_:)``), and free-form tool call arguments.
public enum JSONValue: Codable, Sendable, Hashable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Value is not a valid JSON type"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}

extension JSONValue {
    /// The wrapped value as a Swift `String`, if this is a `.string`.
    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    /// The wrapped value as a Swift `Int`, coercing from `.double` only when losslessly representable.
    public var intValue: Int? {
        switch self {
        case .int(let value): return value
        case .double(let value): return Int(exactly: value)
        default: return nil
        }
    }

    /// The wrapped value as a Swift `Double`, coercing from `.int`.
    public var doubleValue: Double? {
        switch self {
        case .double(let value): return value
        case .int(let value): return Double(value)
        default: return nil
        }
    }

    /// The wrapped value as a Swift `Bool`, if this is a `.bool`.
    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    /// The wrapped value as an array, if this is an `.array`.
    public var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    /// The wrapped value as an object, if this is an `.object`.
    public var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    /// Subscript access into an `.object` value.
    public subscript(key: String) -> JSONValue? {
        if case .object(let dict) = self { return dict[key] }
        return nil
    }
}

extension JSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
}

extension JSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self = .int(value) }
}

extension JSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension JSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}

extension JSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) { self = .array(elements) }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension JSONValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) { self = .null }
}
