# Changelog

## 0.1.1

- Add `@SafeDictionary` for decoding object fields into `[String: Any]`.
- Support encoding `@SafeDictionary` values back to JSON.

## 0.1.0

- Add one-line safe decoding for `SafeCodable` models.
- Add root array decoding for `[Model].safeDecode(from:)`.
- Add JSON encoding helpers for data, string, dictionary, and array output.
- Add fallback behavior for missing, `null`, and invalid fields.
- Add primitive coercion for common `String`, `Int`, `Double`, `Float`, and `Bool` mismatches.
- Add nested model decoding and lossy array handling.
- Add `Date` support for ISO-8601, common date formats, and second/millisecond timestamps.
- Add `Data` Base64 decoding and encoding support.
- Add Chinese and English documentation.
