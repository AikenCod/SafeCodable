# SafeCodable

[English](README.en.md) | 中文

SafeCodable 是一个基于 Swift `Codable` 的轻量 JSON 解析库，目标是：

> 模型照常写，解析一行搞定，脏数据自动兜底。

## 特性

- 一行解析：`User.safeDecode(from: data)`
- 一行转 JSON：`user.safeJSONString()`
- 字段缺失自动使用默认值
- `null` 自动使用默认值或 `nil`
- `String` / `Int` / `Double` / `Float` / `Bool` 常见类型自动转换
- 嵌套模型自动安全解析
- 对象字段可以用 `@SafeDictionary` 接成 `[String: Any]`
- 数组自动跳过 `null` 等无效元素
- 支持 `Date` 常见格式和秒/毫秒时间戳
- 支持 `Data` Base64 解析和编码
- 兼容 `snake_case` 和 `camelCase`

## 安装

在 Xcode 中添加 Swift Package：

```text
git@github.com:AikenCod/SafeCodable.git
```

或在 `Package.swift` 中添加：

```swift
.package(url: "git@github.com:AikenCod/SafeCodable.git", from: "0.1.2")
```

然后在 target 中依赖：

```swift
.product(name: "SafeCodable", package: "SafeCodable")
```

## 基础用法

最简单的使用方式：

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

如果后端返回：

```json
{
  "id": "42",
  "name": null,
  "age": "18",
  "is_vip": 1
}
```

结果会是：

```swift
user.id == 42
user.name == ""
user.age == 18
user.isVIP == true
```

## 类型自动转换

### JSON 数字或布尔值，用 String 接收

JSON：

```json
{
  "id": 10086,
  "price": 99.5,
  "enabled": true
}
```

模型：

```swift
struct Item: SafeCodable {
    var id = ""
    var price = ""
    var enabled = ""
}
```

解析：

```swift
let item = Item.safeDecode(from: data)
```

结果：

```swift
item.id == "10086"
item.price == "99.5"
item.enabled == "true"
```

### JSON 字符串，用 Int / Double / Bool 接收

JSON：

```json
{
  "age": "18",
  "height": "178.5",
  "enabled": "yes",
  "vip": "1"
}
```

模型：

```swift
struct User: SafeCodable {
    var age = 0
    var height = 0.0
    var enabled = false
    var vip = false
}
```

解析：

```swift
let user = User.safeDecode(from: data)
```

结果：

```swift
user.age == 18
user.height == 178.5
user.enabled == true
user.vip == true
```

### JSON 数字，用 Bool 接收

JSON：

```json
{
  "isEnabled": 1,
  "isDeleted": 0
}
```

模型：

```swift
struct State: SafeCodable {
    var isEnabled = false
    var isDeleted = true
}
```

结果：

```swift
state.isEnabled == true
state.isDeleted == false
```

### 无法转换时使用默认值

JSON：

```json
{
  "age": "abc",
  "name": null
}
```

模型：

```swift
struct User: SafeCodable {
    var age = 10
    var name = "unknown"
}
```

结果：

```swift
user.age == 10
user.name == "unknown"
```

## 嵌套模型

JSON：

```json
{
  "name": "Aiken",
  "profile": {
    "avatar": "avatar.png",
    "bio": "iOS Developer"
  }
}
```

模型：

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

结果：

```swift
user.name == "Aiken"
user.profile.avatar == "avatar.png"
```

如果 `profile` 缺失、为 `null` 或结构异常，会使用模型里的默认值：

```swift
user.profile == Profile()
```

## 数组

JSON：

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

模型：

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

解析：

```swift
let user = User.safeDecode(from: data)
```

结果：

```swift
user.posts.map(\.id) == [1, 0, 2]
user.posts.map(\.title) == ["Hello", "Broken", "World"]
user.tags == ["ios", "123", "swift"]
```

数组里的 `null` 会被跳过，元素内部字段错误会使用元素模型默认值。

根节点数组也支持：

JSON：

```json
[
  { "id": "1", "title": "Hello" },
  null,
  { "id": 2, "title": "World" }
]
```

解析：

```swift
let posts = [Post].safeDecode(from: data)
```

结果：

```swift
posts.count == 2
posts[0].id == 1
posts[1].id == 2
```

## 对象字段接收为字典

如果 JSON 里某个 key 对应的是对象，但你不想再建一个模型，可以用 `@SafeDictionary`：

JSON：

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

模型：

```swift
struct Response: SafeCodable {
    var id = 0
    @SafeDictionary var config: [String: Any] = [:]
}
```

解析：

```swift
let response = Response.safeDecode(from: data)
let theme = response.config["theme"] as? String
let retry = response.config["retry"] as? Int
let nested = response.config["nested"] as? [String: Any]
let items = response.config["items"] as? [Any]
```

结果：

```swift
theme == "dark"
retry == 3
nested?["name"] as? String == "SafeCodable"
items?.count == 3
```

Swift 原生裸写 `[String: Any]` 不能自动合成 `Codable`，所以这里需要 wrapper。业务读取到的 `config` 仍然是普通字典。

## Date 和 Data

JSON：

```json
{
  "createdAt": "2026-05-22T10:30:00Z",
  "updatedAt": 1779445800000,
  "payload": "SGVsbG8="
}
```

模型：

```swift
struct Asset: SafeCodable {
    var createdAt: Date?
    var updatedAt: Date?
    var payload: Data?
}
```

解析：

```swift
let asset = Asset.safeDecode(from: data)
let text = asset.payload.flatMap { String(data: $0, encoding: .utf8) }
```

结果：

```swift
asset.createdAt != nil
asset.updatedAt?.timeIntervalSince1970 == 1779445800
text == "Hello"
```

`Date` 默认支持：

- ISO-8601：`2026-05-22T10:30:00Z`
- `yyyy-MM-dd HH:mm:ss`
- `yyyy/MM/dd HH:mm:ss`
- `yyyy-MM-dd`
- `yyyy/MM/dd`
- 秒时间戳
- 毫秒时间戳

`Data` 默认使用 Base64：

```json
{
  "payload": "SGVsbG8="
}
```

## 转 JSON

模型：

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

转成 `Data` / `String` / 字典：

```swift
let data = user.safeJSONData()
let string = user.safeJSONString()
let pretty = user.safeJSONString(prettyPrinted: true)
let dictionary = user.safeDictionary()
```

示例输出：

```json
{
  "id": 7,
  "name": "Aiken",
  "profile": {
    "avatar": "a.png"
  }
}
```

数组：

```swift
let users = [user]
let data = users.safeJSONData()
let string = users.safeJSONString()
let array = users.safeJSONArray()
```

## 默认规则

```text
字段正常          -> 正常解析
字段缺失          -> 使用默认值
字段为 null       -> 非 Optional 使用默认值，Optional 为 nil
数字字符串        -> 自动转数字
数字/字符串/布尔值 -> 常见场景自动互转
嵌套模型失败      -> 使用嵌套模型默认值
对象接收为字典    -> 使用 @SafeDictionary
数组元素为 null   -> 跳过
Date 数字         -> 按秒或毫秒时间戳解析
Data 字符串       -> 按 Base64 解析
```

## 要求

- Swift 5.9+
- iOS 13+
- macOS 10.15+
- tvOS 13+
- watchOS 6+

## License

MIT
