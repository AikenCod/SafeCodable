import Foundation

public protocol SafeCodable: Codable, AnySafeCodable {
    init()
}

public extension SafeCodable {
    static func safeDecode(from data: Data, default defaultValue: Self = Self()) -> Self {
        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            return defaultValue
        }
        return _safeDecode(from: object, defaultValue: defaultValue)
    }

    static func safeDecode(from jsonString: String, default defaultValue: Self = Self()) -> Self {
        safeDecode(from: Data(jsonString.utf8), default: defaultValue)
    }

    func safeJSONData(prettyPrinted: Bool = false) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : []
        return (try? encoder.encode(self)) ?? Data()
    }

    func safeJSONString(prettyPrinted: Bool = false) -> String {
        String(data: safeJSONData(prettyPrinted: prettyPrinted), encoding: .utf8) ?? ""
    }

    func safeDictionary() -> [String: Any]? {
        let object = try? JSONSerialization.jsonObject(with: safeJSONData())
        return object as? [String: Any]
    }
}

public extension Array where Element: SafeCodable {
    static func safeDecode(from data: Data) -> [Element] {
        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            return []
        }
        return SafeValue.decodeArray(Element.self, from: object)
    }
}

public extension Array where Element: Encodable {
    func safeJSONData(prettyPrinted: Bool = false) -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : []
        return (try? encoder.encode(self)) ?? Data()
    }

    func safeJSONString(prettyPrinted: Bool = false) -> String {
        String(data: safeJSONData(prettyPrinted: prettyPrinted), encoding: .utf8) ?? ""
    }

    func safeJSONArray() -> [[String: Any]]? {
        let object = try? JSONSerialization.jsonObject(with: safeJSONData())
        return object as? [[String: Any]]
    }
}

extension SafeCodable {
    static func _safeDecode(from value: Any, defaultValue: Self = Self()) -> Self {
        let decoder = SafeDecoder(value: value, defaultValue: defaultValue)
        return (try? Self(from: decoder)) ?? defaultValue
    }
}
