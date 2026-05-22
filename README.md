# SafeCodable

English | [中文](README.zh-CN.md)

SafeCodable is a lightweight Swift package built on top of `Codable`.

> Write normal models, decode with one line, and survive messy JSON.

## Features

- One-line decoding: `User.safeDecode(from: data)`
- One-line encoding: `user.safeJSONString()`
- Missing fields fall back to property default values
- `null` falls back to defaults or `nil`
- Common coercion for `String`, `Int`, `Double`, `Float`, and `Bool`
- Safe nested model decoding
- Object fields can be captured as `[String: Any]` with `@SafeDictionary`
- Lossy arrays that skip invalid `null` elements
- `Date` support for common strings and second/millisecond timestamps
- `Data` support through Base64 strings
- `snake_case` and `camelCase` compatibility

## Installation

Add the Swift Package in Xcode:

```text
git@github.com:AikenCod/SafeCodable.git
```

Or add it to `Package.swift`:

```swift
.package(url: "git@github.com:AikenCod/SafeCodable.git", from: "0.1.3")
```

Then add the product to your target:

```swift
.product(name: "SafeCodable", package: "SafeCodable")
```

## Basic Usage

The simplest usage:

```swift
import SafeCodable

struct User: SafeCodable {
    var id = 0
    var name = ""
    var age = 0
    var isVIP = false
}

let user = User.safeDecode(from: data)
```

Given this JSON:

```json
{
  "id": "42",
  "name": null,
  "age": "18",
  "is_vip": 1
}
```

The result is:

```swift
user.id == 42
user.name == ""
user.age == 18
user.isVIP == true
```

## Type Coercion

### JSON Numbers or Booleans as Swift String

JSON:

```json
{
  "id": 10086,
  "price": 99.5,
  "enabled": true
}
```

Model:

```swift
struct Item: SafeCodable {
    var id = ""
    var price = ""
    var enabled = ""
}
```

Decode:

```swift
let item = Item.safeDecode(from: data)
```

Result:

```swift
item.id == "10086"
item.price == "99.5"
item.enabled == "true"
```

### JSON Strings as Swift Int, Double, or Bool

JSON:

```json
{
  "age": "18",
  "height": "178.5",
  "enabled": "yes",
  "vip": "1"
}
```

Model:

```swift
struct User: SafeCodable {
    var age = 0
    var height = 0.0
    var enabled = false
    var vip = false
}
```

Decode:

```swift
let user = User.safeDecode(from: data)
```

Result:

```swift
user.age == 18
user.height == 178.5
user.enabled == true
user.vip == true
```

### JSON Numbers as Swift Bool

JSON:

```json
{
  "isEnabled": 1,
  "isDeleted": 0
}
```

Model:

```swift
struct State: SafeCodable {
    var isEnabled = false
    var isDeleted = true
}
```

Result:

```swift
state.isEnabled == true
state.isDeleted == false
```

### Invalid Values Fall Back to Defaults

JSON:

```json
{
  "age": "abc",
  "name": null
}
```

Model:

```swift
struct User: SafeCodable {
    var age = 10
    var name = "unknown"
}
```

Result:

```swift
user.age == 10
user.name == "unknown"
```

## Nested Models

JSON:

```json
{
  "name": "Aiken",
  "profile": {
    "avatar": "avatar.png",
    "bio": "iOS Developer"
  }
}
```

Model:

```swift
struct Profile: SafeCodable {
    var avatar = ""
    var bio = ""
}

struct User: SafeCodable {
    var name = ""
    var profile = Profile()
}

let user = User.safeDecode(from: data)
```

Result:

```swift
user.name == "Aiken"
user.profile.avatar == "avatar.png"
```

If `profile` is missing, `null`, or malformed, SafeCodable uses the model default:

```swift
user.profile == Profile()
```

## Arrays

JSON:

```json
{
  "posts": [
    { "id": "1", "title": "Hello" },
    null,
    { "id": "bad", "title": "Broken" },
    { "id": 2, "title": "World" }
  ],
  "tags": ["ios", null, 123, "swift"]
}
```

Model:

```swift
struct Post: SafeCodable {
    var id = 0
    var title = ""
}

struct User: SafeCodable {
    var posts: [Post] = []
    var tags: [String] = []
}
```

Decode:

```swift
let user = User.safeDecode(from: data)
```

Result:

```swift
user.posts.map(\.id) == [1, 0, 2]
user.posts.map(\.title) == ["Hello", "Broken", "World"]
user.tags == ["ios", "123", "swift"]
```

`null` elements are skipped. Invalid fields inside an element fall back to that element's defaults.

Root arrays are supported too:

JSON:

```json
[
  { "id": "1", "title": "Hello" },
  null,
  { "id": 2, "title": "World" }
]
```

Decode:

```swift
let posts = [Post].safeDecode(from: data)
```

Result:

```swift
posts.count == 2
posts[0].id == 1
posts[1].id == 2
```

## Object Field as Dictionary

Sometimes one JSON key is an object, but you do not want to create another model for it. Use `@SafeDictionary`:

JSON:

```json
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
```

Model:

```swift
struct Response: SafeCodable {
    var id = 0
    @SafeDictionary var config: [String: Any] = [:]
}
```

Decode:

```swift
let response = Response.safeDecode(from: data)
let theme = response.config["theme"] as? String
let retry = response.config["retry"] as? Int
let nested = response.config["nested"] as? [String: Any]
let items = response.config["items"] as? [Any]
```

Result:

```swift
theme == "dark"
retry == 3
nested?["name"] as? String == "SafeCodable"
items?.count == 3
```

Plain `[String: Any]` cannot synthesize `Codable` in Swift, so the wrapper is required. The value you read in business code is still a normal dictionary.

## Date and Data

JSON:

```json
{
  "createdAt": "2026-05-22T10:30:00Z",
  "updatedAt": 1779445800000,
  "payload": "SGVsbG8="
}
```

Model:

```swift
struct Asset: SafeCodable {
    var createdAt: Date?
    var updatedAt: Date?
    var payload: Data?
}
```

Decode:

```swift
let asset = Asset.safeDecode(from: data)
let text = asset.payload.flatMap { String(data: $0, encoding: .utf8) }
```

Result:

```swift
asset.createdAt != nil
asset.updatedAt?.timeIntervalSince1970 == 1779445800
text == "Hello"
```

`Date` supports:

- ISO-8601: `2026-05-22T10:30:00Z`
- `yyyy-MM-dd HH:mm:ss`
- `yyyy/MM/dd HH:mm:ss`
- `yyyy-MM-dd`
- `yyyy/MM/dd`
- second timestamps
- millisecond timestamps

`Data` uses Base64 strings:

```json
{
  "payload": "SGVsbG8="
}
```

## Encoding

Model:

```swift
struct Profile: SafeCodable {
    var avatar = ""
}

struct User: SafeCodable {
    var id = 0
    var name = ""
    var profile = Profile()
}

let user = User(id: 7, name: "Aiken", profile: Profile(avatar: "a.png"))
```

Encode to `Data`, `String`, or dictionary:

```swift
let data = user.safeJSONData()
let string = user.safeJSONString()
let pretty = user.safeJSONString(prettyPrinted: true)
let dictionary = user.safeDictionary()
```

Example output:

```json
{
  "id": 7,
  "name": "Aiken",
  "profile": {
    "avatar": "a.png"
  }
}
```

Arrays:

```swift
let users = [user]
let data = users.safeJSONData()
let string = users.safeJSONString()
let array = users.safeJSONArray()
```

## Default Rules

```text
Valid field           -> decoded normally
Missing field         -> default value
null field            -> default value for non-optional, nil for optional
Numeric string        -> number
Number/string/bool    -> common coercion
Nested model failure  -> nested default value
Object as dictionary  -> @SafeDictionary
Array null element    -> skipped
Date number           -> second or millisecond timestamp
Data string           -> Base64
```

## Requirements

- Swift 5.9+
- iOS 13+
- macOS 10.15+
- tvOS 13+
- watchOS 6+

## License

MIT
