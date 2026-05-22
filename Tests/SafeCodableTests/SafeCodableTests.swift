import Foundation
import XCTest
@testable import SafeCodable

final class SafeCodableTests: XCTestCase {
    func testSafeDecodeUsesDefaultsAndCoercesPrimitiveValues() {
        struct User: SafeCodable, Equatable {
            var id = 0
            var name = ""
            var age = 0
            var score = 0.0
            var isVIP = false
        }

        let json = """
        {
          "id": "42",
          "name": null,
          "age": "18",
          "score": "99.5",
          "is_vip": 1
        }
        """

        let user = User.safeDecode(from: Data(json.utf8))

        XCTAssertEqual(user.id, 42)
        XCTAssertEqual(user.name, "")
        XCTAssertEqual(user.age, 18)
        XCTAssertEqual(user.score, 99.5)
        XCTAssertEqual(user.isVIP, true)
    }

    func testSafeDecodeCoercesNumberAndBoolToString() {
        struct Item: SafeCodable, Equatable {
            var id = ""
            var price = ""
            var enabled = ""
        }

        let json = """
        {
          "id": 10086,
          "price": 99.5,
          "enabled": true
        }
        """

        let item = Item.safeDecode(from: Data(json.utf8))

        XCTAssertEqual(item.id, "10086")
        XCTAssertEqual(item.price, "99.5")
        XCTAssertEqual(item.enabled, "true")
    }

    func testSafeDecodeSupportsNestedModelsAndLossyArrays() {
        struct Profile: SafeCodable, Equatable {
            var avatar = ""
            var bio = ""
        }

        struct Post: SafeCodable, Equatable {
            var id = 0
            var title = ""
        }

        struct User: SafeCodable, Equatable {
            var name = ""
            var profile = Profile()
            var posts: [Post] = []
            var tags: [String] = []
        }

        let json = """
        {
          "name": "Aiken",
          "profile": null,
          "posts": [
            { "id": "1", "title": "Hello" },
            null,
            { "id": "bad", "title": "Broken" },
            { "id": 2, "title": "World" }
          ],
          "tags": ["ios", null, 123, "swift"]
        }
        """

        let user = User.safeDecode(from: Data(json.utf8))

        XCTAssertEqual(user.name, "Aiken")
        XCTAssertEqual(user.profile, Profile())
        XCTAssertEqual(user.posts, [
            Post(id: 1, title: "Hello"),
            Post(id: 0, title: "Broken"),
            Post(id: 2, title: "World")
        ])
        XCTAssertEqual(user.tags, ["ios", "123", "swift"])
    }

    func testSafeDecodeSupportsRootArrays() {
        struct User: SafeCodable, Equatable {
            var id = 0
            var name = ""
        }

        let json = """
        [
          { "id": "1", "name": "Tom" },
          null,
          { "id": 2, "name": "Jerry" }
        ]
        """

        let users = [User].safeDecode(from: Data(json.utf8))

        XCTAssertEqual(users, [
            User(id: 1, name: "Tom"),
            User(id: 2, name: "Jerry")
        ])
    }

    func testSafeDecodeSupportsDateDataAndURL() {
        struct Asset: SafeCodable {
            var createdAt: Date?
            var updatedAt: Date?
            var payload: Data?
            var homepage = URL(string: "https://fallback.example.com")!
            var avatar: URL?
            var invalidURL = URL(string: "https://default.example.com")!
        }

        let json = """
        {
          "createdAt": "2026-05-22T10:30:00Z",
          "updatedAt": 1779445800000,
          "payload": "SGVsbG8=",
          "homepage": "https://example.com/home",
          "avatar": "https://example.com/avatar.png",
          "invalidURL": ""
        }
        """

        let asset = Asset.safeDecode(from: Data(json.utf8))

        XCTAssertNotNil(asset.createdAt)
        XCTAssertEqual(asset.updatedAt?.timeIntervalSince1970, 1_779_445_800)
        XCTAssertEqual(asset.payload.flatMap { String(data: $0, encoding: .utf8) }, "Hello")
        XCTAssertEqual(asset.homepage.absoluteString, "https://example.com/home")
        XCTAssertEqual(asset.avatar?.absoluteString, "https://example.com/avatar.png")
        XCTAssertEqual(asset.invalidURL.absoluteString, "https://default.example.com")
    }

    func testSafeDecodeSupportsDecimal() {
        struct Price: SafeCodable, Equatable {
            var amount = Decimal(0)
            var discount: Decimal?
            var fallback = Decimal(10)
        }

        let json = """
        {
          "amount": "19.99",
          "discount": 2.5,
          "fallback": "bad"
        }
        """

        let price = Price.safeDecode(from: Data(json.utf8))

        XCTAssertEqual(price.amount, Decimal(string: "19.99"))
        XCTAssertEqual(price.discount, Decimal(string: "2.5"))
        XCTAssertEqual(price.fallback, Decimal(10))
    }

    func testSafeDecodeSupportsRawRepresentableEnums() {
        enum Status: String, Codable {
            case unknown
            case active
            case disabled
        }

        enum Level: Int, Codable {
            case low = 1
            case medium = 2
            case high = 3
        }

        struct Account: SafeCodable {
            @SafeEnum var status: Status = .unknown
            @SafeEnum var backupStatus: Status = .disabled
            @SafeEnum var level: Level = .low
            @SafeEnumOptional var optionalStatus: Status? = .unknown
        }

        let json = """
        {
          "status": "active",
          "backupStatus": "missing",
          "level": "3",
          "optionalStatus": null
        }
        """

        let account = Account.safeDecode(from: Data(json.utf8))

        XCTAssertEqual(account.status, .active)
        XCTAssertEqual(account.backupStatus, .disabled)
        XCTAssertEqual(account.level, .high)
        XCTAssertNil(account.optionalStatus)
    }

    func testSafeDecodeSupportsObjectFieldAsDictionary() {
        struct Response: SafeCodable {
            var id = 0
            @SafeDictionary var config: [String: Any] = [:]
        }

        let json = """
        {
          "id": 1,
          "config": {
            "theme": "dark",
            "retry": 3,
            "enabled": true,
            "nested": { "name": "SafeCodable" },
            "items": ["a", 2, false]
          }
        }
        """

        let response = Response.safeDecode(from: Data(json.utf8))

        XCTAssertEqual(response.id, 1)
        XCTAssertEqual(response.config["theme"] as? String, "dark")
        XCTAssertEqual(response.config["retry"] as? Int, 3)
        XCTAssertEqual(response.config["enabled"] as? Bool, true)
        XCTAssertEqual((response.config["nested"] as? [String: Any])?["name"] as? String, "SafeCodable")
        XCTAssertEqual(response.config["items"] as? [Any] as NSArray?, ["a", 2, false] as NSArray)
    }

    func testSafeEncodeOutputsDataStringDictionaryAndArray() throws {
        struct Profile: SafeCodable, Equatable {
            var avatar = ""
        }

        struct User: SafeCodable, Equatable {
            var id = 0
            var name = ""
            var profile = Profile()
        }

        let user = User(id: 7, name: "Aiken", profile: Profile(avatar: "a.png"))

        let data = user.safeJSONData()
        let decoded = try JSONDecoder().decode(User.self, from: data)
        XCTAssertEqual(decoded, user)

        XCTAssertTrue(user.safeJSONString().contains("\"name\":\"Aiken\""))
        XCTAssertEqual(user.safeDictionary()?["id"] as? Int, 7)
        XCTAssertEqual([user].safeJSONArray()?.count, 1)
    }
}
