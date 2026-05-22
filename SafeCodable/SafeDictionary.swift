import Foundation

@propertyWrapper
public struct SafeDictionary: Codable {
    public var wrappedValue: [String: Any]

    public init(wrappedValue: [String: Any] = [:]) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        if let safeDecoder = decoder as? SafeDecoder {
            self.wrappedValue = SafeAnyValue.dictionary(from: safeDecoder.value)
        } else {
            let value = try SafeAnyValue(from: decoder)
            self.wrappedValue = value.rawValue as? [String: Any] ?? [:]
        }
    }

    public func encode(to encoder: Encoder) throws {
        try SafeAnyValue(wrappedValue).encode(to: encoder)
    }
}

extension SafeDictionary: AnySafeRawDecodable {
    static func safeDecodeRaw(from value: Any, defaultValue: Any?) -> Any {
        SafeDictionary(wrappedValue: dictionary(from: value, defaultValue: defaultValue))
    }

    private static func dictionary(from value: Any, defaultValue: Any?) -> [String: Any] {
        let decoded = SafeAnyValue.dictionary(from: value)
        if decoded.isEmpty, let fallback = defaultValue as? SafeDictionary {
            return fallback.wrappedValue
        }
        if decoded.isEmpty, let fallback = defaultValue as? [String: Any] {
            return fallback
        }
        return decoded
    }
}

enum SafeAnyValue: Codable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([SafeAnyValue])
    case object([String: SafeAnyValue])

    init(_ value: Any) {
        if value is NSNull {
            self = .null
        } else if let bool = value as? Bool {
            self = .bool(bool)
        } else if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                self = .bool(number.boolValue)
            } else {
                let double = number.doubleValue
                self = double.rounded() == double ? .int(number.intValue) : .double(double)
            }
        } else if let string = value as? String {
            self = .string(string)
        } else if let array = value as? [Any] {
            self = .array(array.map(SafeAnyValue.init))
        } else if let dictionary = value as? [String: Any] {
            self = .object(dictionary.mapValues(SafeAnyValue.init))
        } else {
            self = .null
        }
    }

    init(from decoder: Decoder) throws {
        if let safeDecoder = decoder as? SafeDecoder {
            self = SafeAnyValue(safeDecoder.value)
            return
        }

        if let keyed = try? decoder.container(keyedBy: SafeCodingKey.self) {
            var object = [String: SafeAnyValue]()
            for key in keyed.allKeys {
                object[key.stringValue] = try keyed.decode(SafeAnyValue.self, forKey: key)
            }
            self = .object(object)
            return
        }

        if var unkeyed = try? decoder.unkeyedContainer() {
            var array = [SafeAnyValue]()
            while !unkeyed.isAtEnd {
                array.append(try unkeyed.decode(SafeAnyValue.self))
            }
            self = .array(array)
            return
        }

        let single = try decoder.singleValueContainer()
        if single.decodeNil() {
            self = .null
        } else if let bool = try? single.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? single.decode(Int.self) {
            self = .int(int)
        } else if let double = try? single.decode(Double.self) {
            self = .double(double)
        } else if let string = try? single.decode(String.self) {
            self = .string(string)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        case .bool(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .int(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .double(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .string(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
        case .array(let values):
            var container = encoder.unkeyedContainer()
            for value in values {
                try container.encode(value)
            }
        case .object(let values):
            var container = encoder.container(keyedBy: SafeCodingKey.self)
            for (key, value) in values {
                try container.encode(value, forKey: SafeCodingKey(stringValue: key))
            }
        }
    }

    var rawValue: Any {
        switch self {
        case .null:
            return NSNull()
        case .bool(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .string(let value):
            return value
        case .array(let values):
            return values.map(\.rawValue)
        case .object(let values):
            return values.mapValues(\.rawValue)
        }
    }

    static func dictionary(from value: Any) -> [String: Any] {
        guard case .object(let object) = SafeAnyValue(value) else {
            return [:]
        }
        return object.mapValues(\.rawValue)
    }
}
