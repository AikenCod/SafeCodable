import Foundation

@propertyWrapper
public struct SafeEnum<Value: Codable & RawRepresentable>: Codable where Value.RawValue: Codable {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let fallback = decoder.safeDefaultValue(as: SafeEnum<Value>.self)?.wrappedValue
        let rawValue = decoder.safeRawValue()
        self.wrappedValue = SafeEnum.decode(from: rawValue, fallback: fallback)
    }

    public func encode(to encoder: Encoder) throws {
        try wrappedValue.rawValue.encode(to: encoder)
    }

    private static func decode(from value: Any?, fallback: Value?) -> Value {
        guard let value, !(value is NSNull) else {
            return fallback ?? fallbackValue()
        }

        if let rawValue = value as? Value.RawValue,
           let decoded = Value(rawValue: rawValue) {
            return decoded
        }

        if let rawValue = SafeEnumRawValue.decode(Value.RawValue.self, from: value),
           let decoded = Value(rawValue: rawValue) {
            return decoded
        }

        return fallback ?? fallbackValue()
    }

    private static func fallbackValue() -> Value {
        if let rawValue = SafeEnumRawValue.fallback(Value.RawValue.self),
           let value = Value(rawValue: rawValue) {
            return value
        }
        preconditionFailure("SafeEnum requires a default value when raw value fallback cannot create an enum case.")
    }
}

extension SafeEnum: AnySafeRawDecodable {
    static func safeDecodeRaw(from value: Any, defaultValue: Any?) -> Any {
        let fallback = (defaultValue as? SafeEnum<Value>)?.wrappedValue
        return SafeEnum(wrappedValue: decode(from: value, fallback: fallback))
    }
}

@propertyWrapper
public struct SafeEnumOptional<Value: Codable & RawRepresentable>: Codable where Value.RawValue: Codable {
    public var wrappedValue: Value?

    public init(wrappedValue: Value?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let fallback = decoder.safeDefaultValue(as: SafeEnumOptional<Value>.self)?.wrappedValue
        let rawValue = decoder.safeRawValue()
        self.wrappedValue = SafeEnum.decodeOptional(from: rawValue, fallback: fallback)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let wrappedValue {
            try container.encode(wrappedValue.rawValue)
        } else {
            try container.encodeNil()
        }
    }
}

extension SafeEnumOptional: AnySafeRawDecodable {
    static func safeDecodeRaw(from value: Any, defaultValue: Any?) -> Any {
        let fallback = (defaultValue as? SafeEnumOptional<Value>)?.wrappedValue
        return SafeEnumOptional(wrappedValue: SafeEnum<Value>.decodeOptional(from: value, fallback: fallback))
    }
}

extension SafeEnum {
    static func decodeOptional(from value: Any?, fallback: Value?) -> Value? {
        guard let value, !(value is NSNull) else {
            return nil
        }
        if let rawValue = value as? Value.RawValue {
            return Value(rawValue: rawValue) ?? fallback
        }
        if let rawValue = SafeEnumRawValue.decode(Value.RawValue.self, from: value) {
            return Value(rawValue: rawValue) ?? fallback
        }
        return fallback
    }
}

private enum SafeEnumRawValue {
    static func decode<RawValue: Codable>(_ type: RawValue.Type, from value: Any) -> RawValue? {
        if type == String.self {
            return SafeValue.decode(String.self, from: value) as? RawValue
        }
        if type == Int.self {
            return SafeValue.decode(Int.self, from: value) as? RawValue
        }
        if type == Double.self {
            return SafeValue.decode(Double.self, from: value) as? RawValue
        }
        if type == Float.self {
            return SafeValue.decode(Float.self, from: value) as? RawValue
        }
        if type == Bool.self {
            return SafeValue.decode(Bool.self, from: value) as? RawValue
        }
        return nil
    }

    static func fallback<RawValue: Codable>(_ type: RawValue.Type) -> RawValue? {
        if type == String.self { return "" as? RawValue }
        if type == Int.self { return 0 as? RawValue }
        if type == Double.self { return 0.0 as? RawValue }
        if type == Float.self { return Float(0) as? RawValue }
        if type == Bool.self { return false as? RawValue }
        return nil
    }
}

private extension Decoder {
    func safeDefaultValue<T>(as type: T.Type) -> T? {
        (self as? SafeDecoder)?.defaultValue as? T
    }

    func safeRawValue() -> Any? {
        if let safeDecoder = self as? SafeDecoder {
            return safeDecoder.value
        }

        if let container = try? singleValueContainer() {
            if container.decodeNil() {
                return NSNull()
            }
            if let bool = try? container.decode(Bool.self) {
                return bool
            }
            if let int = try? container.decode(Int.self) {
                return int
            }
            if let double = try? container.decode(Double.self) {
                return double
            }
            if let string = try? container.decode(String.self) {
                return string
            }
        }
        return nil
    }
}
