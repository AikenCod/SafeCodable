import Foundation
import XCTest
@testable import SafeCodable

final class SafeCodableTests: XCTestCase {
    func testSafeDecodeUsesDefaultsAndCoercesPrimitiveValues() throws {
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
          "isVIP": 1
        }
        """

        let user = User.safeDecode(from: Data(json.utf8))

        XCTAssertEqual(user.id, 42)
        XCTAssertEqual(user.name, "")
        XCTAssertEqual(user.age, 18)
        XCTAssertEqual(user.score, 99.5)
        XCTAssertEqual(user.isVIP, true)
    }

    func testSafeDecodeSupportsNestedModelsAndLossyArrays() throws {
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

    func testSafeDecodeSupportsArraysAtTheRoot() throws {
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

    func testSafeDecodeSupportsDateAndData() throws {
        struct Asset: SafeCodable {
            var createdAt: Date?
            var updatedAt: Date?
            var payload: Data?
        }

        let json = """
        {
          "createdAt": "2026-05-22T10:30:00Z",
          "updatedAt": 1779445800000,
          "payload": "SGVsbG8="
        }
        """

        let asset = Asset.safeDecode(from: Data(json.utf8))

        XCTAssertNotNil(asset.createdAt)
        XCTAssertEqual(asset.updatedAt?.timeIntervalSince1970, 1_779_445_800)
        XCTAssertEqual(asset.payload.flatMap { String(data: $0, encoding: .utf8) }, "Hello")
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

        let string = user.safeJSONString()
        XCTAssertTrue(string.contains("\"name\":\"Aiken\""))

        let dictionary = user.safeDictionary()
        XCTAssertEqual(dictionary?["id"] as? Int, 7)
        XCTAssertEqual(dictionary?["name"] as? String, "Aiken")

        let array = [user].safeJSONArray()
        XCTAssertEqual(array?.count, 1)
    }

    func testSafeDecodeSupportsObjectFieldAsDictionary() throws {
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
            "nested": {
              "name": "SafeCodable"
            },
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

        let dictionary = response.safeDictionary()
        let encodedConfig = dictionary?["config"] as? [String: Any]
        XCTAssertEqual(encodedConfig?["theme"] as? String, "dark")
    }
}
