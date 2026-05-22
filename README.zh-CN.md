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
.package(url: "git@github.com:AikenCod/SafeCodable.git", from: "0.1.0")
```

然后在 target 中依赖：

```swift
.product(name: "SafeCodable", package: "SafeCodable")
```

## 基础用法

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

## 嵌套模型

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

如果 `profile` 缺失、为 `null` 或结构异常，会使用 `Profile()`。

## 数组

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

数组里的 `null` 会被跳过，元素内部字段错误会使用元素模型默认值。

根节点数组也支持：

```swift
let users = [User].safeDecode(from: data)
```

## Date 和 Data

```swift
struct Asset: SafeCodable {
    var createdAt: Date?
    var payload: Data?
}
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

```swift
let data = user.safeJSONData()
let string = user.safeJSONString()
let pretty = user.safeJSONString(prettyPrinted: true)
let dictionary = user.safeDictionary()
```

数组：

```swift
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

