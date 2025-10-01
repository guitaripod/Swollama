import Foundation

/// A tool call made by the model.
///
/// Represents a function call that the model wants to invoke.
public struct ToolCall: Codable, Sendable {
    /// The function call details.
    public let function: FunctionCall

    public init(function: FunctionCall) {
        self.function = function
    }
}


/// Details of a function call.
///
/// Contains the function name and arguments as a JSON string.
public struct FunctionCall: Codable, Sendable {
    /// The name of the function to call.
    public let name: String

    /// The function arguments as a JSON string.
    public let arguments: String

    public init(name: String, arguments: String) {
        self.name = name
        self.arguments = arguments
    }

    private enum CodingKeys: String, CodingKey {
        case name, arguments
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)

        if let argumentsString = try? container.decode(String.self, forKey: .arguments) {
            arguments = argumentsString
        } else if let argumentsDict = try? container.decode([String: Any].self, forKey: .arguments) {
            let data = try JSONSerialization.data(withJSONObject: argumentsDict)
            arguments = String(data: data, encoding: .utf8) ?? "{}"
        } else {
            arguments = "{}"
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)

        if let data = arguments.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let dictionary = jsonObject as? [String: Any] {
            try container.encode(dictionary, forKey: .arguments)
        } else {
            try container.encode(arguments, forKey: .arguments)
        }
    }
}

extension KeyedDecodingContainer {
    func decode(_ type: [String: Any].Type, forKey key: Key) throws -> [String: Any] {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }
}

extension KeyedEncodingContainer {
    mutating func encode(_ value: [String: Any], forKey key: Key) throws {
        var container = self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        try container.encode(value)
    }
}

extension KeyedEncodingContainer where K == JSONCodingKeys {
    mutating func encode(_ value: [String: Any]) throws {
        for (key, val) in value {
            let codingKey = JSONCodingKeys(stringValue: key)
            if let boolValue = val as? Bool {
                try encode(boolValue, forKey: codingKey)
            } else if let stringValue = val as? String {
                try encode(stringValue, forKey: codingKey)
            } else if let intValue = val as? Int {
                try encode(intValue, forKey: codingKey)
            } else if let doubleValue = val as? Double {
                try encode(doubleValue, forKey: codingKey)
            } else if let nestedDictionary = val as? [String: Any] {
                try encode(nestedDictionary, forKey: codingKey)
            } else if let nestedArray = val as? [Any] {
                try encode(nestedArray, forKey: codingKey)
            }
        }
    }

    mutating func encode(_ value: [Any], forKey key: K) throws {
        var container = nestedUnkeyedContainer(forKey: key)
        try container.encode(value)
    }
}

extension UnkeyedEncodingContainer {
    mutating func encode(_ value: [Any]) throws {
        for val in value {
            if let boolValue = val as? Bool {
                try encode(boolValue)
            } else if let stringValue = val as? String {
                try encode(stringValue)
            } else if let intValue = val as? Int {
                try encode(intValue)
            } else if let doubleValue = val as? Double {
                try encode(doubleValue)
            } else if let nestedDictionary = val as? [String: Any] {
                try encode(nestedDictionary)
            } else if let nestedArray = val as? [Any] {
                try encode(nestedArray)
            }
        }
    }

    mutating func encode(_ value: [String: Any]) throws {
        var container = nestedContainer(keyedBy: JSONCodingKeys.self)
        try container.encode(value)
    }
}

private struct JSONCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

extension KeyedDecodingContainer where K == JSONCodingKeys {
    func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        var dictionary = [String: Any]()

        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode([String: Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode([Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }

    func decode(_ type: [Any].Type, forKey key: K) throws -> [Any] {
        var container = try nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [Any].Type) throws -> [Any] {
        var array: [Any] = []
        while !isAtEnd {
            if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let value = try? decode(Int.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode([String: Any].self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode([Any].self) {
                array.append(nestedArray)
            }
        }
        return array
    }

    mutating func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        let container = try nestedContainer(keyedBy: JSONCodingKeys.self)
        return try container.decode(type)
    }
}
