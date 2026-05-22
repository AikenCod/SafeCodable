import Foundation

enum SafeValue {
    static func decode<T: Decodable>(_ type: T.Type, from value: Any, defaultValue: Any? = nil) -> T {
        if let optionalType = T.self as? AnyOptional.Type {
            return optionalType.safeDecodeOptional(from: value) as! T
        }

        if value is NSNull, let fallback = defaultValue as? T {
            return fallback
        }

        if let decoded = decodePrimitive(T.self, from: value, defaultValue: defaultValue) {
            return decoded
        }

        if let rawType = T.self as? AnySafeRawDecodable.Type {
            return rawType.safeDecodeRaw(from: value, defaultValue: defaultValue) as! T
        }

        if let arrayType = T.self as? AnySafeArray.Type {
            return arrayType.safeDecodeArray(from: value) as! T
        }

        if let dictionaryType = T.self as? AnySafeDictionary.Type {
            return dictionaryType.safeDecodeDictionary(from: value) as! T
        }

        if let safeType = T.self as? AnySafeCodable.Type {
            return safeType.safeDecodeAny(from: value, defaultValue: defaultValue) as! T
        }

        if let fallback = defaultValue as? T {
            return fallback
        }

        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return fallbackValue(T.self)
        }
        return decoded
    }

    static func decodeArray<Element: Decodable>(_ elementType: Element.Type, from value: Any) -> [Element] {
        guard let values = value as? [Any] else {
            return []
        }
        return values.compactMap { element in
            guard !(element is NSNull) else {
                return nil
            }
            return decode(Element.self, from: element)
        }
    }

    private static func decodePrimitive<T: Decodable>(
        _ type: T.Type,
        from value: Any,
        defaultValue: Any?
    ) -> T? {
        if type == String.self {
            return decodeString(from: value, defaultValue: defaultValue) as? T
        }
        if type == Int.self {
            return decodeInt(from: value, defaultValue: defaultValue) as? T
        }
        if type == Double.self {
            return decodeDouble(from: value, defaultValue: defaultValue) as? T
        }
        if type == Float.self {
            return Float(decodeDouble(from: value, defaultValue: defaultValue)) as? T
        }
        if type == Bool.self {
            return decodeBool(from: value, defaultValue: defaultValue) as? T
        }
        if type == Date.self {
            return decodeDate(from: value, defaultValue: defaultValue) as? T
        }
        if type == Data.self {
            return decodeData(from: value, defaultValue: defaultValue) as? T
        }
        if type == URL.self {
            return decodeURL(from: value, defaultValue: defaultValue) as? T
        }
        if type == Decimal.self {
            return decodeDecimal(from: value, defaultValue: defaultValue) as? T
        }
        return nil
    }

    private static func decodeString(from value: Any, defaultValue: Any?) -> String {
        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        }
        return defaultValue as? String ?? ""
    }

    private static func decodeInt(from value: Any, defaultValue: Any?) -> Int {
        if let int = value as? Int {
            return int
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let string = value as? String, let int = Int(string.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return int
        }
        return defaultValue as? Int ?? 0
    }

    private static func decodeDouble(from value: Any, defaultValue: Any?) -> Double {
        if let double = value as? Double {
            return double
        }
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let string = value as? String, let double = Double(string.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return double
        }
        return defaultValue as? Double ?? 0
    }

    private static func decodeBool(from value: Any, defaultValue: Any?) -> Bool {
        if let bool = value as? Bool {
            return bool
        }
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let string = value as? String {
            switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "yes", "y", "1":
                return true
            case "false", "no", "n", "0":
                return false
            default:
                break
            }
        }
        return defaultValue as? Bool ?? false
    }

    private static func decodeDate(from value: Any, defaultValue: Any?) -> Date {
        if let date = value as? Date {
            return date
        }
        if let number = value as? NSNumber {
            let timestamp = number.doubleValue
            return Date(timeIntervalSince1970: timestamp > 10_000_000_000 ? timestamp / 1000 : timestamp)
        }
        if let string = value as? String {
            if let date = SafeDateParser.parse(string) {
                return date
            }
            if let timestamp = Double(string) {
                return Date(timeIntervalSince1970: timestamp > 10_000_000_000 ? timestamp / 1000 : timestamp)
            }
        }
        return defaultValue as? Date ?? Date(timeIntervalSince1970: 0)
    }

    private static func decodeData(from value: Any, defaultValue: Any?) -> Data {
        if let data = value as? Data {
            return data
        }
        if let string = value as? String, let data = Data(base64Encoded: string) {
            return data
        }
        return defaultValue as? Data ?? Data()
    }

    private static func decodeURL(from value: Any, defaultValue: Any?) -> URL {
        if let url = value as? URL {
            return url
        }
        if let string = value as? String,
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: string) {
            return url
        }
        return defaultValue as? URL ?? URL(fileURLWithPath: "")
    }

    private static func decodeDecimal(from value: Any, defaultValue: Any?) -> Decimal {
        if let decimal = value as? Decimal {
            return decimal
        }
        if let number = value as? NSNumber {
            return number.decimalValue
        }
        if let string = value as? String,
           let decimal = Decimal(string: string.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return decimal
        }
        return defaultValue as? Decimal ?? Decimal(0)
    }

    private static func fallbackValue<T>(_ type: T.Type) -> T {
        if type == String.self { return "" as! T }
        if type == Int.self { return 0 as! T }
        if type == Double.self { return 0.0 as! T }
        if type == Float.self { return Float(0) as! T }
        if type == Bool.self { return false as! T }
        if type == Date.self { return Date(timeIntervalSince1970: 0) as! T }
        if type == Data.self { return Data() as! T }
        if type == URL.self { return URL(fileURLWithPath: "") as! T }
        if type == Decimal.self { return Decimal(0) as! T }
        return Optional<Any>.none as! T
    }
}

public protocol AnySafeCodable {
    static func safeDecodeAny(from value: Any, defaultValue: Any?) -> Any
}

public extension SafeCodable {
    static func safeDecodeAny(from value: Any, defaultValue: Any?) -> Any {
        _safeDecode(from: value, defaultValue: defaultValue as? Self ?? Self())
    }
}

protocol AnySafeArray {
    static func safeDecodeArray(from value: Any) -> Any
}

extension Array: AnySafeArray where Element: Decodable {
    static func safeDecodeArray(from value: Any) -> Any {
        SafeValue.decodeArray(Element.self, from: value)
    }
}

protocol AnySafeDictionary {
    static func safeDecodeDictionary(from value: Any) -> Any
}

protocol AnySafeRawDecodable {
    static func safeDecodeRaw(from value: Any, defaultValue: Any?) -> Any
}

extension Dictionary: AnySafeDictionary where Key == String, Value: Decodable {
    static func safeDecodeDictionary(from value: Any) -> Any {
        guard let dictionary = value as? [String: Any] else {
            return [String: Value]()
        }
        return dictionary.reduce(into: [String: Value]()) { result, pair in
            guard !(pair.value is NSNull) else {
                return
            }
            result[pair.key] = SafeValue.decode(Value.self, from: pair.value)
        }
    }
}

protocol AnyOptional {
    static func safeDecodeOptional(from value: Any) -> Any
}

extension Optional: AnyOptional where Wrapped: Decodable {
    static func safeDecodeOptional(from value: Any) -> Any {
        guard !(value is NSNull) else {
            return Optional<Wrapped>.none as Any
        }
        return Optional.some(SafeValue.decode(Wrapped.self, from: value)) as Any
    }
}

enum SafeDateParser {
    private static let iso8601 = ISO8601DateFormatter()

    private static let formatters: [DateFormatter] = [
        makeFormatter("yyyy-MM-dd HH:mm:ss"),
        makeFormatter("yyyy/MM/dd HH:mm:ss"),
        makeFormatter("yyyy-MM-dd"),
        makeFormatter("yyyy/MM/dd")
    ]

    static func parse(_ string: String) -> Date? {
        if let date = iso8601.date(from: string) {
            return date
        }
        return formatters.lazy.compactMap { $0.date(from: string) }.first
    }

    private static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }
}

extension String {
    func safeSnakeCased() -> String {
        guard !isEmpty else {
            return self
        }

        return reduce(into: "") { result, character in
            if character.isUppercase {
                if !result.isEmpty {
                    result.append("_")
                }
                result.append(character.lowercased())
            } else {
                result.append(character)
            }
        }
    }

    func safeCamelCased() -> String {
        let parts = split(separator: "_")
        guard let first = parts.first else {
            return self
        }
        return parts.dropFirst().reduce(String(first)) { result, part in
            result + part.prefix(1).uppercased() + part.dropFirst()
        }
    }
}
