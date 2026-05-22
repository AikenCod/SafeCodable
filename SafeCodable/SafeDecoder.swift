import Foundation

final class SafeDecoder: Decoder {
    let value: Any
    let defaultValue: Any?
    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any] = [:]

    init(value: Any, defaultValue: Any? = nil, codingPath: [CodingKey] = []) {
        self.value = value
        self.defaultValue = defaultValue
        self.codingPath = codingPath
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let dictionary = value as? [String: Any] ?? [:]
        let container = SafeKeyedDecodingContainer<Key>(
            dictionary: dictionary,
            defaultValue: defaultValue,
            codingPath: codingPath
        )
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        SafeUnkeyedDecodingContainer(
            values: value as? [Any] ?? [],
            codingPath: codingPath
        )
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        SafeSingleValueDecodingContainer(
            value: value,
            defaultValue: defaultValue,
            codingPath: codingPath
        )
    }
}

struct SafeKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let dictionary: [String: Any]
    let defaultValue: Any?
    let codingPath: [CodingKey]

    var allKeys: [Key] {
        dictionary.keys.compactMap(Key.init(stringValue:))
    }

    func contains(_ key: Key) -> Bool {
        value(for: key) != nil
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        guard let value = value(for: key) else {
            return true
        }
        return value is NSNull
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        let fallback = defaultValue(for: key)
        guard let rawValue = value(for: key), !(rawValue is NSNull) else {
            if let rawType = T.self as? AnySafeRawDecodable.Type {
                return rawType.safeDecodeRaw(from: NSNull(), defaultValue: fallback) as! T
            }
            if let fallback = fallback as? T {
                return fallback
            }
            return SafeValue.decode(T.self, from: NSNull(), defaultValue: fallback)
        }
        return SafeValue.decode(T.self, from: rawValue, defaultValue: fallback)
    }

    func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T: Decodable {
        guard let rawValue = value(for: key), !(rawValue is NSNull) else {
            return nil
        }
        return SafeValue.decode(T.self, from: rawValue, defaultValue: defaultValue(for: key))
    }

    func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        let rawValue = value(for: key) ?? [:]
        return try SafeDecoder(
            value: rawValue,
            defaultValue: defaultValue(for: key),
            codingPath: codingPath + [key]
        ).container(keyedBy: type)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        let rawValue = value(for: key) ?? []
        return try SafeDecoder(
            value: rawValue,
            defaultValue: defaultValue(for: key),
            codingPath: codingPath + [key]
        ).unkeyedContainer()
    }

    func superDecoder() throws -> Decoder {
        SafeDecoder(value: dictionary, defaultValue: defaultValue, codingPath: codingPath)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        SafeDecoder(
            value: value(for: key) ?? [:],
            defaultValue: defaultValue(for: key),
            codingPath: codingPath + [key]
        )
    }

    private func value(for key: Key) -> Any? {
        if let direct = dictionary[key.stringValue] {
            return direct
        }
        let snake = key.stringValue.safeSnakeCased()
        if let converted = dictionary[snake] {
            return converted
        }
        let lowercasedKey = key.stringValue.lowercased()
        return dictionary.first { candidate, _ in
            candidate.lowercased() == lowercasedKey || candidate.safeCamelCased().lowercased() == lowercasedKey
        }?.value
    }

    private func defaultValue(for key: Key) -> Any? {
        guard let defaultValue else {
            return nil
        }
        return Mirror(reflecting: defaultValue).children.first { child in
            child.label == key.stringValue ||
            child.label == "_\(key.stringValue)" ||
            child.label?.safeSnakeCased() == key.stringValue
        }?.value
    }
}

struct SafeUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    let values: [Any]
    let codingPath: [CodingKey]
    var currentIndex = 0
    var count: Int? { values.count }
    var isAtEnd: Bool { currentIndex >= values.count }

    mutating func decodeNil() throws -> Bool {
        guard !isAtEnd else {
            return true
        }
        if values[currentIndex] is NSNull {
            currentIndex += 1
            return true
        }
        return false
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        defer { currentIndex += 1 }
        return SafeValue.decode(T.self, from: values[currentIndex])
    }

    mutating func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        defer { currentIndex += 1 }
        return try SafeDecoder(value: values[currentIndex], codingPath: codingPath).container(keyedBy: type)
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        defer { currentIndex += 1 }
        return try SafeDecoder(value: values[currentIndex], codingPath: codingPath).unkeyedContainer()
    }

    mutating func superDecoder() throws -> Decoder {
        defer { currentIndex += 1 }
        return SafeDecoder(value: values[currentIndex], codingPath: codingPath)
    }
}

struct SafeSingleValueDecodingContainer: SingleValueDecodingContainer {
    let value: Any
    let defaultValue: Any?
    let codingPath: [CodingKey]

    func decodeNil() -> Bool {
        value is NSNull
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        SafeValue.decode(Bool.self, from: value, defaultValue: defaultValue)
    }

    func decode(_ type: String.Type) throws -> String {
        SafeValue.decode(String.self, from: value, defaultValue: defaultValue)
    }

    func decode(_ type: Double.Type) throws -> Double {
        SafeValue.decode(Double.self, from: value, defaultValue: defaultValue)
    }

    func decode(_ type: Float.Type) throws -> Float {
        SafeValue.decode(Float.self, from: value, defaultValue: defaultValue)
    }

    func decode(_ type: Int.Type) throws -> Int {
        SafeValue.decode(Int.self, from: value, defaultValue: defaultValue)
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        Int8(SafeValue.decode(Int.self, from: value, defaultValue: defaultValue))
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        Int16(SafeValue.decode(Int.self, from: value, defaultValue: defaultValue))
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        Int32(SafeValue.decode(Int.self, from: value, defaultValue: defaultValue))
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        Int64(SafeValue.decode(Int.self, from: value, defaultValue: defaultValue))
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        UInt(SafeValue.decode(Int.self, from: value, defaultValue: defaultValue))
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        UInt8(SafeValue.decode(Int.self, from: value, defaultValue: defaultValue))
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        UInt16(SafeValue.decode(Int.self, from: value, defaultValue: defaultValue))
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        UInt32(SafeValue.decode(Int.self, from: value, defaultValue: defaultValue))
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        UInt64(SafeValue.decode(Int.self, from: value, defaultValue: defaultValue))
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        SafeValue.decode(T.self, from: value, defaultValue: defaultValue)
    }
}
