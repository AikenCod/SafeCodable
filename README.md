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
.package(url: "git@github.com:AikenCod/SafeCodable.git", from: "0.1.1")
```

Then add the product to your target:

```swift
.product(name: "SafeCodable", package: "SafeCodable")
```

## Basic Usage

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

## Nested Models

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

If `profile` is missing, `null`, or malformed, SafeCodable uses `Profile()`.

## Arrays

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

`null` elements are skipped. Invalid fields inside an element fall back to that element's defaults.

Root arrays are supported too:

```swift
let users = [User].safeDecode(from: data)
```

## Object Field as Dictionary

Sometimes one JSON key is an object, but you do not want to create another model for it. Use `@SafeDictionary`:

```swift
struct Response: SafeCodable {
    var id = 0
    @SafeDictionary var config: [String: Any] = [:]
}

let response = Response.safeDecode(from: data)
let theme = response.config["theme"] as? String
let retry = response.config["retry"] as? Int
let nested = response.config["nested"] as? [String: Any]
```

Example JSON:

```json
{
  "id": 1,
  "config": {
    "theme": "dark",
    "retry": 3,
    "nested": {
      "name": "SafeCodable"
    }
  }
}
```

Plain `[String: Any]` cannot synthesize `Codable` in Swift, so the wrapper is required. The value you read in business code is still a normal dictionary.

## Date and Data

```swift
struct Asset: SafeCodable {
    var createdAt: Date?
    var payload: Data?
}
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

```swift
let data = user.safeJSONData()
let string = user.safeJSONString()
let pretty = user.safeJSONString(prettyPrinted: true)
let dictionary = user.safeDictionary()
```

Arrays:

```swift
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
